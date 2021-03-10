--luacheck: ignore 143/module

local http_formdecode = require "net.http".formdecode;

local secret = module:get_option_string("invites_bootstrap_secret");
if not secret then return; end

local invites_bootstrap_store = module:open_store("invites_bootstrap");

-- This should be a non-negative integer higher than any set for the
-- previous bootstrap event (if any)
local current_index = module:get_option_number("invites_bootstrap_index");

local invites = module:depends("invites");
module:depends("http");

local function handle_request(event)
	local query_params = http_formdecode(event.request.url.query);

	if not query_params.token or query_params.token ~= secret then
		return 403;
	end

	local bootstrap_records = invites_bootstrap_store:get() or {};
	if #bootstrap_records > 0 then
		local last_bootstrap = bootstrap_records[#bootstrap_records];
		if current_index == last_bootstrap.index then
			event.response.headers.Location = last_bootstrap.result;
			return 303;
		elseif current_index < last_bootstrap.index then
			return 410;
		end
	end

	-- Create invite
	local invite, invite_err = invites.create_account(nil, {
		roles = { ["prosody:admin"] = true };
		source = "api/token/bootstrap-"..current_index;
	});
	if not invite then
		module:log("error", "Failed to create bootstrap invite! %s", invite_err);
		return 500;
	end

	-- Record this bootstrap event (to prevent replay)
	table.insert(bootstrap_records, {
		index = current_index;
		timestamp = os.time();
		result = invite.landing_page or invite.uri;
	});
	local record_ok, record_err = invites_bootstrap_store:set(bootstrap_records);
	if not record_ok then
		module:log("error", "Failed to store bootstrap record: %s", record_err);
		return 500;
	end

	event.response.headers.Location = invite.landing_page or invite.uri;
	return 303;
end

module:provides("http", {
	route = {
		GET = handle_request;
	};
});
