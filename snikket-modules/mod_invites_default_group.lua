-- This module adds groupless invites created via the app to
-- the default group
module:hook("invite-created", function (invite)
	if invite.type == "roster"
	and not (invite.additional_data and invite.additional_data.groups) then
		if not invite.addititional_data then
			invite.additional_data = {};
		end
		invite.additional_data.groups = { "default" };
	end
end);
