local DOMAIN = assert(ENV_SNIKKET_DOMAIN, "Please set the SNIKKET_DOMAIN environment variable")
local XMPP_DOMAIN = ENV_SNIKKET_TWEAK_XMPP_DOMAIN or ENV_SNIKKET_DOMAIN;

local RETENTION_DAYS = tonumber(ENV_SNIKKET_RETENTION_DAYS) or 7;

if prosody.process_type == "prosody" and not prosody.config_loaded then
	-- Wait at startup for certificates
	local lfs, socket = require "lfs", require "socket";
	local cert_path = "/etc/prosody/certs/"..XMPP_DOMAIN..".crt";
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

	-- Push notifications
		"cloud_notify";
		"cloud_notify_encrypted";
		"cloud_notify_priority_tag";
		"cloud_notify_filters";

	-- HTTP modules
		"bosh"; -- Enable BOSH clients, aka "Jabber over HTTP"
		"websocket"; -- XMPP over WebSockets
		"http_host_status_check"; -- Health checks over HTTP

	-- Other specific functionality
		"limits"; -- Enable bandwidth limiting for XMPP connections
		"watchregistrations"; -- Alert admins of registrations
		"proxy65"; -- Enables a file transfer proxy service which clients behind NAT can use
		"smacks";
		"email";
		"http_altconnect";
		"bookmarks";
		"default_bookmarks";
		"update_check";
		"update_notify";
		"turncredentials";
		"admin_shell";

	-- Spam/abuse management
		"spam_reporting"; -- Allow users to report spam/abuse
		"watch_spam_reports"; -- Alert admins of spam/abuse reports by users

	-- TODO...
		--"groups"; -- Shared roster support
		--"server_contact_info"; -- Publish contact information for this service
		--"announce"; -- Send announcement to all online users
		--"motd"; -- Send a message to users when they log in
		"welcome"; -- Welcome users who register accounts
		"http_files"; -- Serve static files from a directory over HTTP
		"reload_modules";

	-- Invites
		"invites";
		"invites_adhoc";
		"invites_api";
		"invites_groups";
		"invites_page";
		"invites_register";
		"invites_register_api";
		"invites_tracking";
		"invites_default_group";
		"invites_bootstrap";

		"firewall";

	-- Circles
		"groups_internal";
		"groups_migration";
		"groups_muc_bookmarks";

	-- For the web portal
		"http_oauth2";
		"http_admin_api";
		"rest";

	-- Monitoring & maintenance
		"measure_process";
}

registration_watchers = {} -- Disable by default
registration_notification = "New user registered: $username"

reload_global_modules = { "http" }

http_ports  = { ENV_SNIKKET_TWEAK_INTERNAL_HTTP_PORT or 5280 }
http_interfaces = { ENV_SNIKKET_TWEAK_INTERNAL_HTTP_INTERFACE or "127.0.0.1" }

https_ports = {};

legacy_ssl_ports = { 5223 }

allow_registration = true
registration_invite_only = true

-- This disables in-app invites for non-admins
-- TODO: The plan is to enable it once we can
-- give the admin more fine-grained control
-- over what happens when a user invites someone.
allow_contact_invites = false

invites_page = ENV_SNIKKET_INVITE_URL or ("https://"..DOMAIN.."/invite/{invite.token}/");
invites_page_external = true

invites_bootstrap_index = tonumber(ENV_TWEAK_SNIKKET_BOOTSTRAP_INDEX)
invites_bootstrap_secret = ENV_TWEAK_SNIKKET_BOOTSTRAP_SECRET

c2s_require_encryption = true
s2s_require_encryption = true
s2s_secure_auth = true

archive_expires_after = ("%dd"):format(RETENTION_DAYS) -- Remove archived messages after N days

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

if ENV_SNIKKET_TWEAK_PROMETHEUS == "1" then
	-- When using Prometheus, it is desirable to let the prometheus scraping
	-- drive the sampling of metrics
	statistics_interval = "manual"
else
	-- When not using Prometheus, we need an interval so that the metrics can
	-- be shown by the web portal. The HTTP admin API exposure does not force
	-- a collection as it is only interested in very few specific metrics.
	statistics_interval = 60
end

certificates = "certs"

group_default_name = ENV_SNIKKET_SITE_NAME or XMPP_DOMAIN

-- Update check configuration
software_name = "Snikket"
update_notify_version_url = "https://snikket.org/updates/{branch}/{version}"
update_notify_support_url = "https://snikket.org/notices/{branch}/"
update_notify_message_url = "https://snikket.org/notices/{branch}/{message}"

if ENV_SNIKKET_UPDATE_CHECK ~= "0" then
	update_check_dns = "_{branch}.update.snikket.net"
	update_check_interval = 21613 -- ~6h
end

http_default_host = DOMAIN
http_host = DOMAIN
http_external_url = "https://"..DOMAIN.."/"

if ENV_SNIKKET_TWEAK_TURNSERVER ~= "0" or ENV_SNIKKET_TWEAK_TURNSERVER_DOMAIN then
	turncredentials_host = ENV_SNIKKET_TWEAK_TURNSERVER_DOMAIN or DOMAIN
	turncredentials_secret = ENV_SNIKKET_TWEAK_TURNSERVER_SECRET or assert(io.open("/snikket/prosody/turn-auth-secret-v2")):read("*l");
end

VirtualHost (XMPP_DOMAIN)
	authentication = "internal_hashed"

	http_files_dir = "/var/www"
	http_paths = {
		files = "/";
		landing_page = "/";
		invites_page = "/invite";
		invites_register = "/register";
	}

	if ENV_SNIKKET_TWEAK_PROMETHEUS == "1" then
		modules_enabled = {
			"prometheus";
		}
	end

	welcome_message = [[Hi, welcome to Snikket on $host! Thanks for joining us.]]
	.."\n\n"
	..[[For help and enquiries related to this service you may contact the admin via email: ]]
	..ENV_SNIKKET_ADMIN_EMAIL
	.."\n\n"
	..[[Happy chatting!]]

Component ("groups."..XMPP_DOMAIN) "muc"
	modules_enabled = {
		"muc_mam";
		"muc_local_only";
		"vcard_muc";
		"muc_defaults";
	}
	restrict_room_creation = "local"
	muc_local_only = { "general@groups."..XMPP_DOMAIN }
	muc_room_default_persistent = true
	muc_room_default_allow_member_invites = true

	default_mucs = {
		{
			jid_node = "general";
			config = {
				name = "General Chat";
				description = "Welcome to "..XMPP_DOMAIN.." general chat!";
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

Component ("share."..XMPP_DOMAIN) "http_file_share"
	-- For backwards compat, allow HTTP upload on the base domain
	if ENV_SNIKKET_TWEAK_SHARE_DOMAIN ~= "1" then
		http_host = "share."..DOMAIN
		http_external_url = "https://share."..DOMAIN.."/"
	end
	http_file_share_size_limit = 1024 * 1024 * 16 -- 16MB
	http_file_share_expire_after = 60 * 60 * 24 * RETENTION_DAYS -- N days
	http_paths = {
		file_share = "/upload"
	}

Include (ENV_SNIKKET_TWEAK_EXTRA_CONFIG or "/snikket/prosody/*.cfg.lua")
