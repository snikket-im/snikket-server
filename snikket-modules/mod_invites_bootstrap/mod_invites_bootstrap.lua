--luacheck: ignore 143/module

local http_formdecode = require "net.http".formdecode;

local secret = module:get_option_string("invites_bootstrap_secret");
if not secret then return; end

local invites_bootstrap_store = module:open_store("invites_bootstrap");
local bootstrap_records = invites_bootstrap_store:get() or {};

local index = module:get_option_number("invites_bootstrap_index");
if #bootstrap_records > 0 and (index or -1) <= bootstrap_records[#bootstrap_records].index then
	module:log("debug", "Already bootstrapped for index %d", index or 0);
	return;
end

local invites = module:depends("invites");
module:depends("http");

local function handle_request(event)
	local query_params = http_formdecode(event.request.url.query);

	if not query_params.token or query_params.token ~= secret then
		return 403;
	end

	local invite, err = invites.create_account(nil, {
		roles = { ["prosody:admin"] = true };
		source = "api/token/bootstrap";
	});
	if not invite then
		module:log("error", "Failed to create bootstrap invite! %s", err);
		return 500;
	end

	table.insert(bootstrap_records, {
		index = index;
		timestamp = os.time();
	});

	event.response.headers.Location = invite.landing_page or invite.uri;

	return 201;
end

module:provides("http", {
	route = {
		GET = handle_request;
	};
});
