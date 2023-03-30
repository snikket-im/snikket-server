local um_get_jid_role = require "core.usermanager".get_jid_role;

local function load_groups_host(module)
	local primary_host = module.host:gsub("^%a+%.", "");

	local function is_restricted(user_jid)
		local role = um_get_jid_role(user_jid, primary_host);
		return not role or role.name == "prosody:restricted";
	end

	module:hook("muc-config-submitted/muc#roomconfig_publicroom", function (event)
		if not is_restricted(event.actor) then return; end
		-- Don't allow modification of this value by restricted users
		return true;
	end, 5);

	module:hook("muc-config-form", function (event)
		if not is_restricted(event.actor) then return; end -- Don't restrict admins
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
end
