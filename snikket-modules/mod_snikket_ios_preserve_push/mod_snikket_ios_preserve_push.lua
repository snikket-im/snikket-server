-- The Snikket iOS client does not perform a push registration ("enable") on
-- every new connection (it connects every time the app is opened, so we want
-- to reduce round-trips and latency). This module attempts to locate a push
-- registration associated with the connecting client, and load it onto the
-- session so that mod_cloud_notify can find it.

local push_store = module:open_store("cloud_notify");

module:hook("resource-bind", function (event)
	local session = event.session;
	local client_id = session.client_id;
	if not client_id then return; end
	local push_registrations = push_store:get(session.username);
	if not push_registrations then return; end
	for push_identifier, push_registration in pairs(push_registrations) do
		if push_registration.client_id == client_id then
			session.push_identifier = push_identifier;
			session.push_settings = push_registration;
			module:log("debug", "Restored push registration for %s (%s)", client_id, push_identifier);
			break;
		end
	end
end, 10);
