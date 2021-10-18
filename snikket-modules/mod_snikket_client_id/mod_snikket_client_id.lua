-- This module assigns a client_id to sessions if they are using a "Snikket.*"
-- resource identifier. We assume that a resource string in this format is
-- static for the same client instance across every session.
--
-- In the future it is anticipated that this "hack" will be replaced by SASL 2
-- (XEP-0388) and/or Bind 2 (XEP-0386), however this is not yet implemented in
-- Prosody or any clients.

module:hook("resource-bind", function (event)
	local id = event.session.resource:match("^Snikket%..+$");
	if not id then return; end
	event.session.client_id = id;
end, 1000);
