local jid_bare = require "util.jid".bare;
local um_get_roles = require "core.usermanager".get_roles;

local function check_user_isolated(event)
	local session = event.session;
	if not session.no_host_isolation then
		local bare_jid = jid_bare(session.full_jid);
		local roles = um_get_roles(bare_jid, module.host);
		if roles and not roles["prosody:restricted"] then
			-- Bypass isolation for all unrestricted users
			session.no_host_isolation = true;
		end
	end
end

module:hook("resource-bind", check_user_isolated, -0.5);
