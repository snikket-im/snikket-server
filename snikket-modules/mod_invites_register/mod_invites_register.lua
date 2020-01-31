local id = require "util.id";
local http_formdecode = require "net.http".formdecode;
local usermanager = require "core.usermanager";
local nodeprep = require "util.encodings".stringprep.nodeprep;
local st = require "util.stanza";
local url_escape = require "util.http".urlencode;
local render_html_template = require"util.interpolation".new("%b{}", st.xml_escape, {
	urlescape = url_escape;
});


local site_name = module:get_option_string("site_name", module.host);

module:depends("http");
module:depends("easy_invite");
local invites = module:depends("invites");
local invites_page = module:depends("invites_page");

function serve_register_page(event)
	local register_page_template = assert(module:load_resource("html/register.html")):read("*a");

	local invite = invites.get(event.request.url.query);
	if not invite then
		return {
			status_code = 303;
			headers = {
				["Location"] = invites.module:http_url().."?"..event.request.url.query;
			};
		};
	end

	local invite_page = render_html_template(register_page_template, {
		site_name = site_name;
		token = invite.token;
		domain = module.host;
		uri = invite.uri;
		type = invite.type;
		jid = invite.jid;
	});
	return invite_page;
end

function handle_register_form(event)
	local request, response = event.request, event.response;
	local form_data = http_formdecode(request.body);
	local user, password, token = form_data["user"], form_data["password"], form_data["token"];

	local register_page_template = assert(module:load_resource("html/register.html")):read("*a");
	local error_template = assert(module:load_resource("html/register_error.html")):read("*a");
	local success_template = assert(module:load_resource("html/register_success.html")):read("*a");

	local invite = invites.get(token);
	if not invite then
		return {
			status_code = 303;
			headers = {
				["Location"] = invites_page.module:http_url().."?"..event.request.url.query;
			};
		};
	end

	response.headers.content_type = "text/html; charset=utf-8";

	if not user or #user == 0 or not password or #password == 0 or not token then
		return render_html_template(register_page_template, {
			site_name = site_name;
			token = invite.token;
			domain = module.host;
			uri = invite.uri;
			type = invite.type;
			jid = invite.jid;

			msg_class = "alert-warning";
			message = "Please fill in all fields.";
		});
	end

	-- Shamelessly copied from mod_register_web.
	local prepped_username = nodeprep(user);

	if not prepped_username or #prepped_username == 0 then
		return render_html_template(register_page_template, {
			site_name = site_name;
			token = invite.token;
			domain = module.host;
			uri = invite.uri;
			type = invite.type;
			jid = invite.jid;

			msg_class = "alert-warning";
			message = "This username contains invalid characters.";
		});
	end

	if usermanager.user_exists(prepped_username, module.host) then
		return render_html_template(register_page_template, {
			site_name = site_name;
			token = invite.token;
			domain = module.host;
			uri = invite.uri;
			type = invite.type;
			jid = invite.jid;

			msg_class = "alert-warning";
			message = "This username is already in use.";
		});
	end

	local registering = {
		validated_invite = invite;
		username = prepped_username;
		host = module.host;
		allowed = true;
	};

	module:fire_event("user-registering", registering);

	if not registering.allowed then
		return render_html_template(error_template, {
			site_name = site_name;
			msg_class = "alert-danger";
			message = registering.reason or "Registration is not allowed.";
		});
	end

	local ok, err = usermanager.create_user(prepped_username, password, module.host);

	if ok then
		module:fire_event("user-registered", {
			username = prepped_username;
			host = module.host;
			source = "mod_"..module.name;
			validated_invite = invite;
		});

		return render_html_template(success_template, {
			site_name = site_name;
			username = prepped_username;
			domain = module.host;
			password = password;
		});
	else
		local err_id = id.short();
		module:log("warn", "Registration failed (%s): %s", err_id, tostring(err));
		return render_html_template(error_template, {
			site_name = site_name;
			msg_class = "alert-danger";
			message = ("An unknown error has occurred (%s)"):format(err_id);
		});
	end
end

module:provides("http", {
	route = {
		["GET"] = serve_register_page;
		["POST"] = handle_register_form;
	};
});
