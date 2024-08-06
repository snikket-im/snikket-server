
local st = require "prosody.util.stanza";

module:add_feature("jabber:iq:version");
local query = st.stanza("query", {xmlns = "jabber:iq:version"})
	:text_tag("name", "Snikket")
	:text_tag("version", "");

module:hook("iq-get/host/jabber:iq:version:query", function(event)
	local origin, stanza = event.origin, event.stanza;
	origin.send(st.reply(stanza):add_child(query));
	return true;
end);
