local http_formdecode = require "net.http".formdecode;

local api_key_store;
local invites;
-- COMPAT: workaround to avoid executing inside prosodyctl
if prosody.shutdown then
	module:depends("http");
	api_key_store = module:open_store("invite_api_keys", "map");
	invites = module:depends("invites");
end

local function get_api_user(request, params)
	local combined_key;

	local auth_header = request.headers.authorization;

	if not auth_header then
		params = params or http_formdecode(request.url.query);
		combined_key = params.key;
	else
		local auth_type, value = auth_header:match("^(%S+)%s(%S+)$");
		if auth_type ~= "Bearer" then
			return;
		end
		combined_key = value;
	end

	if not combined_key then
		return;
	end

	local key_id, key_token = combined_key:match("^([^/]+)/(.+)$");

	if not key_id then
		return;
	end

	local api_user = api_key_store:get(nil, key_id);

	if not api_user or api_user.token ~= key_token then
		return;
	end

	-- TODO: key expiry, rate limiting, etc.
	return api_user;
end

function handle_request(event)
	local query_params = http_formdecode(event.request.url.query);

	local api_user = get_api_user(event.request, query_params);

	if not api_user then
		return 403;
	end

	local invite = invites.create_account(nil, { source = "api/token/"..api_user.id });
	if not invite then
		return 500;
	end

	event.response.headers.Location = invite.landing_page or invite.uri;

	if query_params.redirect then
		return 303;
	end
	return 201;
end

if invites then
	module:provides("http", {
		route = {
			["GET"] = handle_request;
		};
	});
end

function module.command(arg)
	local host = table.remove(arg, 1);
	if not prosody.hosts[host] then
		print("Error: please supply a valid host");
		return 1;
	end
	require "core.storagemanager".initialize_host(host);
	module.host = host; --luacheck: ignore 122/module
	api_key_store = module:open_store("invite_api_keys", "map");

	local command = table.remove(arg, 1);
	if command == "create" then
		local id = require "util.id".short();
		local token = require "util.id".long();
		api_key_store:set(nil, id, {
			id = id;
			token = token;
			name = arg[1];
			created_at = os.time();
		});
		print(id.."/"..token);
	elseif command == "delete" then
		local id = table.remove(arg, 1);
		if not api_key_store:get(nil, id) then
			print("Error: key not found");
			return 1;
		end
		api_key_store:set(nil, id, nil);
	elseif command == "list" then
		local api_key_store_kv = module:open_store("invite_api_keys");
		for key_id, key_info in pairs(api_key_store_kv:get(nil)) do
			print(key_id, key_info.name or "<unknown>");
		end
	end
end
