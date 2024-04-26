local base64 = require "prosody.util.encodings".base64;
local hashes = require "prosody.util.hashes";
local st = require "prosody.util.stanza";

local site_logo = module:get_option_path("site_logo", "logo.png", "config");
local site_name = module:get_option_string("site_name", os.getenv("SNIKKET_SITE_NAME") or module.host);

local mime_types = { png = "image/png", jpeg = "image/jpeg", jpg = "image/jpeg", svg = "image/svg+xml" };

local function build_service_vcard()
	local service_vcard, avatar_hash;

	service_vcard = st.stanza("vCard", { xmlns = "vcard-temp" })
		:text_tag("FN", site_name);

	if site_logo then
		local f, err = io.open(site_logo);
		if not f then
			module:log("warn", "Failed to open site_logo file: %s", err);
		else
			local data = f:read("*a");
			f:close();
			avatar_hash = hashes.sha1(data, true);
			service_vcard
				:tag("PHOTO")
					:text_tag("BINVAL", base64.encode(data))
					:text_tag("TYPE", mime_types[site_logo:match("%.(%w+)$")])
				:up();
		end
	end
	service_vcard:reset();

	return service_vcard, avatar_hash;
end

local service_vcard, avatar_hash = build_service_vcard();

module:hook("iq/host/vcard-temp:vCard", function (event)
	local stanza = event.stanza;

	if stanza.attr.to ~= module.host or stanza.attr.type ~= "get" then
		return;
	end

	module:log("debug", "Serving vcard to %s", stanza.attr.from);

	local reply = st.reply(stanza):add_child(service_vcard);
	event.origin.send(reply);
	return true;
end, 10);

module:hook("presence/initial", function (event)
	if not avatar_hash then
		module:log("debug", "Skipping sending of avatar hash we don't have");
		return;
	end
	local pres = st.presence({ from = module.host, type = "unavailable" })
		:tag("x", { xmlns = "vcard-temp:x:update" })
			:text_tag("photo", avatar_hash)
		:up();
	module:log("info", "Sending avatar hash: %s", pres);
	event.origin.send(pres);
end);
