local st = require "util.stanza";
local url_escape = require "util.http".urlencode;

local render_html_template = require"util.interpolation".new("%b{}", st.xml_escape, {
	urlescape = url_escape;
});
local render_url = require "util.interpolation".new("%b{}", url_escape, {
	urlescape = url_escape;
	noscheme = function (url)
		return (url:gsub("^[^:]+:", ""));
	end;
});

local site_name = module:get_option_string("site_name", module.host);

if prosody.shutdown then
	module:depends("http");
end
local invites = module:depends("invites");

-- Point at eg https://github.com/ge0rg/easy-xmpp-invitation
local base_url = module:get_option_string("invites_page", (module.http_url and module:http_url().."?{token}") or nil);

local function add_landing_url(invite)
	if not base_url then return; end
	invite.landing_page = render_url(base_url, invite);
end

module:hook("invite-created", add_landing_url);


function serve_invite_page(event)
	local invite_page_template = assert(module:load_resource("html/invite.html")):read("*a");
	local invalid_invite_page_template = assert(module:load_resource("html/invite_invalid.html")):read("*a");

	local invite = invites.get(event.request.url.query);
	if not invite then
		return render_html_template(invalid_invite_page_template, { site_name = site_name });
	end

	local invite_page = render_html_template(invite_page_template, {
		site_name = site_name;
		token = invite.token;
		uri = invite.uri;
		type = invite.type;
		jid = invite.jid;
	});
	return invite_page;
end

module:provides("http", {
	route = {
		["GET"] = serve_invite_page;
	};
});
