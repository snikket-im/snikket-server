local DOMAIN = assert(ENV_SNIKKET_DOMAIN, "Please set the SNIKKET_DOMAIN environment variable")

if prosody.process_type == "prosody" and not prosody.config_loaded then
	-- Wait at startup for certificates
	local lfs, socket = require "lfs", require "socket";
	local cert_path = "/etc/prosody/certs/"..DOMAIN..".crt";
	local counter = 0;
	while not lfs.attributes(cert_path, "mode") do
		counter = counter + 1;
		if counter == 1 or counter%6 == 0 then
			print("Waiting for certificates...");
		elseif counter > 60 then
			print("No certificates found... exiting");
			os.exit(1);
		end
		socket.sleep(5);
	end
	_G.ltn12 = require "ltn12";
end

daemonize = false
network_backend = "epoll"

plugin_paths = { "/etc/prosody/modules" }

data_path = "/snikket/prosody"

pidfile = "/var/run/prosody/prosody.pid"

modules_enabled = {

	-- Generally required
		"roster"; -- Allow users to have a roster. Recommended ;)
		"saslauth"; -- Authentication for clients and servers. Recommended if you want to log in.
		"tls"; -- Add support for secure TLS on c2s/s2s connections
		"disco"; -- Service discovery

	-- Not essential, but recommended
		"carbons"; -- Keep multiple clients in sync
		"pep"; -- Enables users to publish their avatar, mood, activity, playing music and more
		"blocklist"; -- Allow users to block communications with other users
		"vcard4"; -- User profiles (stored in PEP)
		"vcard_legacy"; -- Conversion between legacy vCard and PEP Avatar, vcard

	-- Nice to have
		"version"; -- Replies to server version requests
		"uptime"; -- Report how long server has been running
		"time"; -- Let others know the time here on this server
		"ping"; -- Replies to XMPP pings with pongs
		"register"; -- Allow users to register on this server using a client and change passwords
		"mam"; -- Store messages in an archive and allow users to access it
		"csi_simple"; -- Simple Mobile optimizations
		"cloud_notify"; -- Push notifications

	-- HTTP modules
		"bosh"; -- Enable BOSH clients, aka "Jabber over HTTP"
		"websocket"; -- XMPP over WebSockets
		"http_acme_challenge";
		"http_libjs";

	-- Other specific functionality
		"limits"; -- Enable bandwidth limiting for XMPP connections
		"watchregistrations"; -- Alert admins of registrations
		"proxy65"; -- Enables a file transfer proxy service which clients behind NAT can use
		"smacks";
		"email";
		"http_altconnect";
		"bookmarks";
		"default_bookmarks";
		"roster_allinall";
		"update_check";
		"update_notify";
		"turncredentials";
		"admin_shell";

	-- TODO...
		--"groups"; -- Shared roster support
		--"server_contact_info"; -- Publish contact information for this service
		--"announce"; -- Send announcement to all online users
		--"motd"; -- Send a message to users when they log in
		"welcome"; -- Welcome users who register accounts
		"http_files"; -- Serve static files from a directory over HTTP
		"reload_modules";
		"landing_page";
		"invites_page";
		"invites_register";
		"invites_api";
		"easy_invite";
		"watchregistrations";
		"firewall";
}

registration_watchers = {} -- Disable by default
registration_notification = "New user registered: $username"

reload_global_modules = { "http" }

http_ports  = { ENV_SNIKKET_TWEAK_HTTP_PORT or 80 }
https_ports = { ENV_SNIKKET_TWEAK_HTTPS_PORT or 443 }

legacy_ssl_ports = { 5223 }

allow_registration = true
registration_invite_only = true

invites_page = ENV_SNIKKET_INVITE_URL or ("https://"..DOMAIN.."/invite?{token}");

c2s_require_encryption = true
s2s_require_encryption = true
s2s_secure_auth = true

archive_expires_after = "1w" -- Remove archived messages after 1 week

-- Disable IPv6 by default because Docker does not
-- have it enabled by default, and s2s to domains
-- with A+AAAA records breaks (as opposed to just AAAA)
-- TODO: implement happy eyeballs in net.connect
-- https://issues.prosody.im/1246
use_ipv6 = (ENV_SNIKKET_TWEAK_IPV6 == "1")

log = {
	[ENV_SNIKKET_LOGLEVEL or "info"] = "*stdout"
}

authentication = "internal_hashed"
authorization = "internal"
storage = "internal"
statistics = "internal"

certificates = "certs"

-- Update check configuration
software_name = "Snikket"
update_notify_version_url = "https://snikket.org/updates/{branch}/{version}"
update_notify_support_url = "https://snikket.org/notices/{branch}/"
update_notify_message_url = "https://snikket.org/notices/{branch}/{message}"
update_check_dns = "_{branch}.update.snikket.net"
update_check_interval = 3607

http_host = DOMAIN
http_external_url = "https://"..DOMAIN.."/"

turncredentials_host = DOMAIN
turncredentials_secret = assert(io.open("/snikket/prosody/turn-auth-secret-v2")):read("*l");

VirtualHost (DOMAIN)
	authentication = "internal_hashed"

	http_files_dir = "/var/www"
	http_paths = {
		files = "/";
		landing_page = "/";
		invites_page = "/invite";
		invites_register = "/register";
	}

	default_bookmarks = {
		{ jid = "general@groups."..DOMAIN, name = "General Chat" };
	}

	welcome_message = [[Hi, welcome to Snikket on $host!

]]
..[[Thanks for joining. We've automatically added you to the "General Chat" group ]]
..[[where you can chat with other members of $host. You'll find it under 'Bookmarks'.

]]
..[[Snikket is in its early stages right now, so thanks for trying it out, ]]
..[[we hope you like it!

]]..[[That's all for now, happy chatting!]]

Component ("groups."..DOMAIN) "muc"
	modules_enabled = {
		"muc_mam";
		"muc_local_only";
		"vcard_muc";
		"muc_defaults";
	}
	restrict_room_creation = "local"
	muc_local_only = { "general@groups."..DOMAIN }
	muc_room_default_persistent = true
	muc_room_default_allow_member_invites = true

	default_mucs = {
		{
			jid_node = "general";
			config = {
				name = "General Chat";
				description = "Welcome to "..DOMAIN.." general chat!";
				change_subject = false;
				history_length = 30;
				members_only = false;
				moderated = false;
				persistent = true;
				public = true;
				public_jids = true;
			};
		}
	}

Component ("share."..DOMAIN) "http_upload"
	http_upload_file_size_limit = 1024 * 1024 * 10 -- 10MB

Include "/snikket/prosody/*.cfg.lua"
