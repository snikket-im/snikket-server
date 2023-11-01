local data_path = "/snikket/prosody";

local vhost = {
	"accounts";
	"account_details";
	"account_roles";
	"roster";
	"vcard";
	"private";
	"blocklist";
	"privacy";
	"archive-archive";
	"offline-archive";
	"pubsub_nodes-pubsub";
	"pep-pubsub";
	"cron";
	"fast_tokens";
	"clients";
	"cloud_notify";
	"smacks_h";
	"lastlog2";
	"invite_token";
	"invite_api_keys";
	"invites_tracking";
	"invites_bootstrap";
	"update_notifications";
	"groups";
	"group_info";
}
local muc = {
	"persistent";
	"config";
	"state";
	"muc_log-archive";
	"vcard_muc";
	"cron";
};
local upload = {
	"uploads-archive";
	"upload_stats";
	"cron";
}

local hosts = {
	-- Real domain subsituted from entrypoint.sh
	["SNIKKET_DOMAIN"] = vhost;
	["share.SNIKKET_DOMAIN"] = upload;
	["groups.SNIKKET_DOMAIN"] = muc;
}

files {
	hosts = hosts;
	type = "internal";
	path = "/snikket/prosody";
}

sqlite {
	hosts = hosts;
	type = "sql";
	driver = "SQLite3";
	database = "/snikket/prosody/prosody.sqlite";
}
