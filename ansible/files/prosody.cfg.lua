local DOMAIN = assert(ENV_SNIKKET_DOMAIN, "Please set the SNIKKET_DOMAIN environment variable")

local RETENTION_DAYS = tonumber(ENV_SNIKKET_RETENTION_DAYS) or 7;
local UPLOAD_STORAGE_GB = tonumber(ENV_SNIKKET_UPLOAD_STORAGE_GB);

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

network_backend = "epoll"

plugin_paths = { "/etc/prosody/modules" }

data_path = "/snikket/prosody"

pidfile = "/var/run/prosody/prosody.pid"

admin_shell_prompt = ("prosody [%s]> "):format(DOMAIN)

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
		"password_policy";

	-- Nice to have
		"version"; -- Replies to server version requests
		"uptime"; -- Report how long server has been running
		"time"; -- Let others know the time here on this server
		"ping"; -- Replies to XMPP pings with pongs
		"register"; -- Allow users to register on this server using a client and change passwords
		"mam"; -- Store messages in an archive and allow users to access it
		"csi_simple"; -- Simple Mobile optimizations

	-- SASL2/FAST
		"sasl2";
		"sasl2_bind2";
		"sasl2_sm";
		"sasl2_fast";
		"client_management";

	-- Event auditing
		"audit";
		"audit_auth"; -- Audit authentication attempts and new clients
		"audit_status"; -- Audit status changes of the server (start, stop, crash)
		"audit_user_accounts"; -- Audit status changes of user accounts (created, deleted, etc.)

	-- Push notifications
		"cloud_notify";
		"cloud_notify_extensions";

	-- HTTP modules
		"bosh"; -- Enable BOSH clients, aka "Jabber over HTTP"
		"websocket"; -- XMPP over WebSockets
		"http_host_status_check"; -- Health checks over HTTP
		"http_xep227";

	-- Other specific functionality
		"limits"; -- Enable bandwidth limiting for XMPP connections
		"watchregistrations"; -- Alert admins of registrations
		"proxy65"; -- Enables a file transfer proxy service which clients behind NAT can use
		"smacks";
		"email";
		"http_altconnect";
		"bookmarks";
		"update_check";
		"update_notify";
		"turn_external";
		"admin_shell";
		"isolate_host";
		"snikket_client_id";
		"snikket_ios_preserve_push";
		"snikket_restricted_users";
		"lastlog2";

	-- Spam/abuse management
		"spam_reporting"; -- Allow users to report spam/abuse
		"watch_spam_reports"; -- Alert admins of spam/abuse reports by users
		"server_contact_info"; -- Publish contact information for this service

	-- TODO...
		--"groups"; -- Shared roster support
		--"announce"; -- Send announcement to all online users
		--"motd"; -- Send a message to users when they log in
		"http_files"; -- Serve static files from a directory over HTTP

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
		"measure_active_users";
		"measure_lua";
		"measure_malloc";
		"portcheck";
}

registration_watchers = {} -- Disable by default
registration_notification = "New user registered: $username"

contact_info = {
	abuse = ENV_SNIKKET_ABUSE_EMAIL and {"mailto:"..ENV_SNIKKET_ABUSE_EMAIL} or nil;
	security = ENV_SNIKKET_SECURITY_EMAIL and {"mailto:"..ENV_SNIKKET_SECURITY_EMAIL} or nil;
}

http_ports  = { ENV_SNIKKET_TWEAK_INTERNAL_HTTP_PORT or 5280 }
http_interfaces = { ENV_SNIKKET_TWEAK_INTERNAL_HTTP_INTERFACE or "127.0.0.1" }
http_max_content_size = 1024 * 1024 -- non-streaming uploads limited to 1MB (improves RAM usage)

https_ports = {};

c2s_direct_tls_ports = { 5223 }

allow_registration = true
registration_invite_only = true

password_policy = {
	length = 10;
}

-- In the future we want to switch to SASL2 for better security,
-- as client ids are not supported in SASL1 (identification is via
-- the resource string, which is semi-public and not authenticated)
-- This tweak is for developers to test with the future configuration,
-- or people who want to opt into the new security sooner.
enforce_client_ids = ENV_SNIKKET_TWEAK_REQUIRE_SASL2 == "1"

-- This disables in-app invites for non-admins
-- TODO: The plan is to enable it once we can
-- give the admin more fine-grained control
-- over what happens when a user invites someone.
allow_contact_invites = false

-- Disallow restricted users to create invitations to the server
deny_user_invites_by_roles = { "prosody:restricted" }

-- This role was renamed 'guest' in Prosody.
custom_roles = { { name = "prosody:restricted"; priority = 15 } }

invites_page = ENV_SNIKKET_INVITE_URL or ("https://"..DOMAIN.."/invite/{invite.token}/");
invites_page_external = true

invites_bootstrap_index = tonumber(ENV_TWEAK_SNIKKET_BOOTSTRAP_INDEX)
invites_bootstrap_secret = ENV_TWEAK_SNIKKET_BOOTSTRAP_SECRET
invites_bootstrap_ttl = tonumber(ENV_TWEAK_SNIKKET_BOOTSTRAP_TTL or (28 * 86400)) -- default 28 days

-- The Resource Owner Credentials grant used internally between the web portal
-- and Prosody, so ensure this is enabled. Other unused flows can be disabled.
allowed_oauth2_grant_types = { "password" }
allowed_oauth2_response_types = {}

-- Longer access token lifetime than the default
-- TODO: Use the already longer-lived refresh tokens
oauth2_access_token_ttl = 86400

c2s_require_encryption = true
s2s_require_encryption = true
s2s_secure_auth = true

-- Grant federation privileges to regular users but not restricted users.
-- This is enforced by mod_isolate_host.
add_permissions = {
	["prosody:registered"] = {
		"xmpp:federate";
	};
}

archive_expires_after = ("%dd"):format(RETENTION_DAYS) -- Remove archived messages after N days

-- Delay full account deletion via IBR for RETENTION_DAYS, to allow restoration
-- in case of accidental or malicious deletion of an account
registration_delete_grace_period = ("%d days"):format(RETENTION_DAYS)

-- Allow disabling IPv6 because Docker does not have it enabled by default, but
-- we don't use Docker networking so it should not matter.
use_ipv6 = (ENV_SNIKKET_TWEAK_IPV6 ~= "0")

log = {
	[ENV_SNIKKET_LOGLEVEL or "info"] = "*stdout"
}

authentication = "internal_hashed"
authorization = "internal"
disable_sasl_mechanisms = { "PLAIN" }

if ENV_SNIKKET_TWEAK_STORAGE == "sqlite" then
	storage = "sql"
	sql = {
		driver = "SQLite3";
		database = "/snikket/prosody/prosody.sqlite";
	}
else
	storage = "internal"
end

statistics = "internal"

if ENV_SNIKKET_TWEAK_PROMETHEUS == "1" then
	-- TODO rename to OPENMETRICS
	-- When using Prometheus, it is desirable to let the prometheus scraping
	-- drive the sampling of metrics
	statistics_interval = "manual"
else
	-- When not using Prometheus, we need an interval so that the metrics can
	-- be shown by the web portal. The HTTP admin API exposure does not force
	-- a collection as it is only interested in very few specific metrics.
	statistics_interval = 60
end

if ENV_SNIKKET_TWEAK_DNSSEC == "1" then
	local trustfile = "/usr/share/dns/root.ds"; -- Requires apt:dns-root-data
	-- Bail out if it doesn't work
	assert(require"lunbound".new{ resolvconf = true; trustfile = trustfile }:resolve ".".secure,
		"Upstream DNS resolver is not DNSSEC-capable. Fix this or disable SNIKKET_TWEAK_DNSSEC");
	unbound = { trustfile = trustfile }

	-- Since we have DNSSEC, we can also do DANE
	use_dane = true
end

certificates = "certs"

group_default_name = ENV_SNIKKET_SITE_NAME or DOMAIN

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
	turn_external_host = ENV_SNIKKET_TWEAK_TURNSERVER_DOMAIN or DOMAIN
	turn_external_secret = ENV_SNIKKET_TWEAK_TURNSERVER_SECRET or assert(io.open("/snikket/prosody/turn-auth-secret-v2")):read("*l");
end

-- Allow restricted users access to push notification servers
isolate_except_domains = { "push.snikket.net", "push-ios.snikket.net" }

VirtualHost (DOMAIN)
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
			"http_openmetrics";
		}
	end

Component ("groups."..DOMAIN) "muc"
	modules_enabled = {
		"muc_mam";
		"muc_local_only";
		"vcard_muc";
		"muc_defaults";
		"muc_offline_delivery";
		"snikket_restricted_users";
		"snikket_deprecate_general_muc";
		"muc_auto_reserve_nicks";
	}
	restrict_room_creation = "local"

	-- Some older deployments may have the general@ MUC, so we still need
	-- to protect it:
	muc_local_only = { "general@groups."..DOMAIN }

	-- Default configuration for rooms (typically overwritten by the client)
	muc_room_default_allow_member_invites = true
	muc_room_default_persistent = true
	muc_room_default_public = false

	-- Enable push notifications for offline group members by default
	-- (this also requires mod_muc_auto_reserve_nicks in practice)
	muc_offline_delivery_default = true
	-- Include form in MUC registration query result (required for app
	-- to detect whether push notifications are enabled)
	muc_registration_include_form = true


Component ("share."..DOMAIN) "http_file_share"
	-- For backwards compat, allow HTTP upload on the base domain
	if ENV_SNIKKET_TWEAK_SHARE_DOMAIN ~= "1" then
		http_host = "share."..DOMAIN
		http_external_url = "https://share."..DOMAIN.."/"
	end

	-- 128 bits (i.e. 16 bytes) is the maximum length of a GCM auth tag, which
	-- is appended to encrypted uploads according to XEP-0454. This ensures we
	-- allow files up to the size limit even if they are encrypted.
	http_file_share_size_limit = (1024 * 1024 * 100) + 16 -- 100MB + 16 bytes
	http_file_share_expires_after = 60 * 60 * 24 * RETENTION_DAYS -- N days

	if UPLOAD_STORAGE_GB then
		http_file_share_global_quota = 1024 * 1024 * 1024 * UPLOAD_STORAGE_GB
	end
	http_paths = {
		file_share = "/upload"
	}

Include (ENV_SNIKKET_TWEAK_EXTRA_CONFIG or "/snikket/prosody/*.cfg.lua")
