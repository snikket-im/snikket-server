local role_store = module:open_store("roles");

function get_user_roles(user)
	return role_store:get(user);
end

function get_jid_roles(jid) --luacheck: ignore 212/jid
	return nil;
end
