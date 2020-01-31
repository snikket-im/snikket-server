local http_formdecode = require "net.http".formdecode;
local st = require "util.stanza";
local render_html_template = require"util.interpolation".new("%b{}", st.xml_escape);
local render_text_template = require"util.interpolation".new("%b{}", function (s) return s; end);
local mime = require "mime";
local ltn12 = require "ltn12";

local site_name = module:get_option_string("site_name", module.host);

-- Email templates
local email_template_preamble = "Problems viewing this email? View it online at {invite_page}";
local email_template_text = assert(module:load_resource("email_templates/invite_email.txt")):read("*a");
local email_template_html = assert(module:load_resource("email_templates/invite_email.html")):read("*a");

module:depends("http");
module:depends("email");
local invites = module:depends("invites");

local landing_page_template = assert(module:load_resource("html/index.html")):read("*a");

local landing_page = render_html_template(landing_page_template, {
	site_name = site_name;
});

local function handle_form(event)
	local request, response = event.request, event.response;
	local form_data = http_formdecode(request.body);

	local email = form_data["email"];

	response.headers.content_type = "";

	local invite = invites.create_account();

	local email_template_params = {
		site_name = site_name;
		invite_token = invite.token;
		invite_uri = invite.uri;
		invite_page = invite.landing_page;
	};

	local email_headers = {
		Subject = "Your Snikket invitation";
		["Content-Type"] = "multipart/mixed";
	};

	local email_body = {
		-- Optional text content prefixed to the entire email (visible even in
		-- non-MIME clients)
		preamble = render_text_template(email_template_preamble, email_template_params);

		-- Plain text version
		[1] = {
			headers = {
				["Content-Type"] = 'text/plain; charset="utf-8"';
			};
			body = mime.eol(0, render_text_template(email_template_text, email_template_params));
		};

		-- HTML version
		[2] = {
			headers = {
				["content-type"] = 'text/html;charset="utf-8"',
				["content-transfer-encoding"] = "quoted-printable"
			},
			body = ltn12.source.chain(
				ltn12.source.string(render_html_template(email_template_html, email_template_params)),
				ltn12.filter.chain(
					mime.encode("quoted-printable", "text"),
					mime.wrap()
				)
			);
		};
	}


	module:send_email({ --luacheck: ignore 143/module
		to = email;
		headers = email_headers;
		body = email_body;
	});

	return render_html_template(landing_page_template, {
		site_name = site_name;
		message = "Ok! Check your inbox :)";
	});
end

module:provides("http", {
	route = {
		["GET /"] = landing_page;
		["POST /invite-request"] = handle_form;
	};
});
