
local st = require "prosody.util.stanza";
local paths = require "prosody.util.paths";
snikket_version = "";

function module.load()
	local version_filename = paths.join(prosody.paths.source, "snikket.version");
	local version_fh, err = io.open(version_filename);
	if not version_fh then
		module:log("error", "Could not discover Snikket version: %s", err);
		return
	end
	snikket_version = version_fh:read();
	version_fh:close();
end

module:add_feature("jabber:iq:version");
module:hook("iq-get/host/jabber:iq:version:query", function(event)
	local origin, stanza = event.origin, event.stanza;

	origin.send(st.reply(stanza):query("jabber:iq:version")
			:text_tag("name", "Snikket")
			:text_tag("version", snikket_version));
	return true;
end);
