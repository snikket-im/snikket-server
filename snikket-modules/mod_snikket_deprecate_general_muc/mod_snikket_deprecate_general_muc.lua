local mod_muc = module:depends("muc");

local general = mod_muc.get_room_from_jid("general@"..module.host);
if general then
	local state = os.getenv("SNIKKET_TWEAK_GENERAL_MUC") or "hidden";
	if state == "hidden" then
		if general:get_public() then
			general:set_public(false);
			module:log("info", "Set general MUC to hidden");
		end
	elseif state == "destroyed" then
		general:destroy(nil, "General chat is deprecated");
		module:log("info", "Destroyed general MUC");
	else
		module:log("warn", "Unknown desired state: %s", state);
	end
end
