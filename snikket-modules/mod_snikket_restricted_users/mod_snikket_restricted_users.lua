local jid_bare = require "util.jid".bare;
local um_get_roles = require "core.usermanager".get_roles;

local function load_main_host(module)
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
end

local function load_groups_host(module)
	local primary_host = module.host:gsub("^%a+%.", "");

	local function is_restricted(user_jid)
		local roles = um_get_roles(user_jid, primary_host);
		return not roles or roles["prosody:restricted"];
	end

	module:hook("muc-config-submitted/muc#roomconfig_publicroom", function (event)
		if not is_restricted(event.stanza.attr.from) then return; end
		-- Don't allow modification of this value by restricted users
		return true;
	end, 5);

	module:hook("muc-config-form", function (event)
		if not is_restricted(event.stanza.attr.from) then return; end -- Don't restrict admins
		-- Hide the option from the config form for restricted users
		local form = event.form;
		for i = #form, 1, -1 do
			if form[i].name == "muc#roomconfig_publicroom" then
				table.remove(form, i);
			end
		end
	end);
end

if module:get_host_type() == "component" and module:get_option_string("component_module") == "muc" then
	load_groups_host(module);
else
	load_main_host(module);
end
