local id = require "util.id";
local url = require "socket.url";
local jid_node = require "util.jid".node;

local invite_ttl = module:get_option_number("invite_expiry", 86400 * 7);

local token_storage = module:open_store("invite_token", "map");

local function get_uri(action, jid, token, params) --> string
	return url.build({
			scheme = "xmpp",
			path = jid,
			query = action..";preauth="..token..(params and (";"..params) or ""),
		});
end

local function create_invite(invite_action, invite_jid, allow_registration, additional_data)
	local token = id.medium();

	local created_at = os.time();
	local expires = created_at + invite_ttl;

	local invite_params = (invite_action == "roster" and allow_registration) and "ibr=y" or nil;

	local invite = {
		type = invite_action;
		jid = invite_jid;

		token = token;
		allow_registration = allow_registration;
		additional_data = additional_data;

		uri = get_uri(invite_action, invite_jid, token, invite_params);

		created_at = created_at;
		expires = expires;
	};

	module:fire_event("invite-created", invite);

	if allow_registration then
		local ok, err = token_storage:set(nil, token, invite);
		if not ok then
			module:log("warn", "Failed to store account invite: %s", err);
			return nil, "internal-server-error";
		end
	end

	if invite_action == "roster" then
		local username = jid_node(invite_jid);
		local ok, err = token_storage:set(username, token, expires);
		if not ok then
			module:log("warn", "Failed to store subscription invite: %s", err);
			return nil, "internal-server-error";
		end
	end

	return invite;
end

-- Create invitation to register an account (optionally restricted to the specified username)
function create_account(account_username, additional_data) --luacheck: ignore 131/create_account
	local jid = account_username and (account_username.."@"..module.host) or module.host;
	return create_invite("register", jid, true, additional_data);
end

-- Create invitation to become a contact of a local user
function create_contact(username, allow_registration, additional_data) --luacheck: ignore 131/create_contact
	return create_invite("roster", username.."@"..module.host, allow_registration, additional_data);
end

local valid_invite_methods = {};
local valid_invite_mt = { __index = valid_invite_methods };

function valid_invite_methods:use()
	if self.username then
		-- Also remove the contact invite if present, on the
		-- assumption that they now have a mutual subscription
		token_storage:set(self.username, self.token, nil);
	end
	token_storage:set(nil, self.token, nil);
	return true;
end

-- Get a validated invite (or nil, err). Must call :use() on the
-- returned invite after it is actually successfully used
-- For "roster" invites, the username of the local user (who issued
-- the invite) must be passed.
-- If no username is passed, but the registration is a roster invite
-- from a local user, the "inviter" field of the returned invite will
-- be set to their username.
function get(token, username)
	if not token then
		return nil, "no-token";
	end

	local valid_until, inviter;

	-- Fetch from host store (account invite)
	local token_info = token_storage:get(nil, token);

	if username then -- token being used for subscription
		-- Fetch from user store (subscription invite)
		valid_until = token_storage:get(username, token);
	else -- token being used for account creation
		valid_until = token_info and token_info.expires;
		if token_info and token_info.type == "roster" then
			username = jid_node(token_info.jid);
			inviter = username;
		end
	end

	if not valid_until then
		module:log("debug", "Got unknown token: %s", token);
		return nil, "token-invalid";
	elseif os.time() > valid_until then
		module:log("debug", "Got expired token: %s", token);
		return nil, "token-expired";
	end

	return setmetatable({
		token = token;
		username = username;
		inviter = inviter;
		type = token_info and token_info.type or "roster";
		uri = token_info and token_info.uri or get_uri("roster", username.."@"..module.host, token);
		additional_data = token_info and token_info.additional_data or nil;
	}, valid_invite_mt);
end

function use(token) --luacheck: ignore 131/use
	local invite = get(token);
	return invite and invite:use();
end
