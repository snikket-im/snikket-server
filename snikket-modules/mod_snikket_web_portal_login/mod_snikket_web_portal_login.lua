local dataforms = require "prosody.util.dataforms";
local http = require "prosody.net.http";
local jid = require "prosody.util.jid";
local st = require "prosody.util.stanza";
local usermanager = require "prosody.core.usermanager";

local adhoc_new = module:require("adhoc").new;
local tokens = module:depends("tokenauth");

local command_node = "admin";

local portal_url = module:get_option_string("web_portal_url", "https://"..module.host.."/login");
local token_ttl = module:get_option_number("oauth2_access_token_ttl", 3600);
local requested_roles = {
	"prosody:restricted";
	"prosody:registered";
	"prosody:admin";
};

local function get_scopes_and_role(username)
	local scopes = {};
	local selected_role;
	for _, role_name in ipairs(requested_roles) do
		if usermanager.user_can_assume_role(username, module.host, role_name) then
			table.insert(scopes, role_name);
			selected_role = selected_role or role_name;
		end
	end
	return table.concat(scopes, " "), selected_role;
end

local result_form = dataforms.new({
	title = "Admin panel";
	{
		name = "url";
		label = "Link";
		desc = "Open this link in a web browser";
	};
});

local function create_portal_url(from)
	local username, host = jid.split(from);
	if host ~= module.host or not username then
		return nil, "This command is only available to users of "..module.host;
	end

	local scopes, role = get_scopes_and_role(username);
	if not role then
		return nil, "Unable to determine your account role";
	end

	local grant, grant_err = tokens.create_grant(from, from, nil, {
		oauth2_scopes = scopes;
		oauth2_client = nil;
	});
	if not grant then
		module:log("error", "Failed to create portal login grant for %s: %s", from, grant_err);
		return nil, "Unable to create a login link";
	end

	local token, token_err = tokens.create_token(from, grant.id, role, token_ttl, "oauth2");
	if not token then
		module:log("error", "Failed to create portal login token for %s: %s", from, token_err);
		return nil, "Unable to create a login link";
	end

	return portal_url.."?"..http.formencode({ token = token; jid = from; scope = scopes; });
end

module:provides("adhoc", adhoc_new("Admin panel", command_node,
	function (_, data)
		local url, err = create_portal_url(jid.bare(data.from));
		if not url then
			return { status = "completed"; error = { message = err; }; };
		end
		return {
			status = "completed";
			other = st.stanza("x", { xmlns = "jabber:x:oob" }):text_tag("url", url);
			-- Do not include fallback for now because we can't force it to
			-- be ordered after the oob tag as it should be
			--result = {
			--	layout = result_form;
			--	values = {
			--		url = url;
			--	};
			--};
		};
	end, "local_user"));
