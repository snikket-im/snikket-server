local urlencode = require "util.http".urlencode;
local interpolation = require "util.interpolation";

local render_url = interpolation.new("%b{}", urlencode);
local render_text = interpolation.new("%b{}", function (s) return s; end);

local security_notification = [[There is an important security release available
for {software}. The latest secure version is {current.branch}.{latest.secure}.
You are currently running {software} {current.branch}.{current.level}.


For more information please see: {url}
]];

local version_notification = [[There is a new {software} release available. You are
currently running {software} {current.branch}.{current.level}, and an upgrade to
{current.branch}.{latest.latest} is now available.

For more information please see: {url}
]];

local message_notification = [[There is a new announcement related to {software}, for more
information please see: {url}
]];

local support_notification = [[This version of {software} is no longer supported. For
more information please see: {url}
]]

local software_name = module:get_option_string("software_name");
local version_url = module:get_option_string("update_notify_version_url");
local support_url = module:get_option_string("update_notify_support_url");
local message_url = module:get_option_string("update_notify_message_url");

if not (software_name and version_url and support_url and message_url) then
	return error("Requires software name, version, support and message URLs to be set");
end

local admin_notify = module:depends("admin_notify").notify;

local notified_store = module:open_store("update_notifications", "map");

local function have_notified(branch, field, value)
	local notified_value = notified_store:get(branch, field);
	if notified_value then
		if type(value) == "number" and notified_value >= value then
			return true;
		elseif notified_value == value then
			return true;
		end
	end

	notified_store:set(branch, field, value);
	return false;
end

module:hook("update-check/result", function (event)
	local branch = event.current.branch;
	local ver_secure = tonumber(event.latest.secure);
	local ver_latest = tonumber(event.latest.latest);
	local ver_installed = tonumber(event.current.level);
	local msg_latest = tonumber(event.latest.msg);

	if not ver_installed then
		module:log_status("error", "Unable to determine local version number");
		return;
	end

	if ver_secure and ver_installed < ver_secure
	and not have_notified(branch, "secure", ver_secure) then
		module:log_status("warn", "Security update available!");
		admin_notify(render_text(security_notification, {
			software = software_name;
			current = event.current;
			latest = event.latest;
			url = render_url(version_url, { branch = branch, version = event.latest.secure });
		}));
		return;
	end

	if ver_latest and ver_installed < ver_latest
	and not have_notified(branch, "latest", ver_latest) then
		module:log_status("info", "Update available!");
		admin_notify(render_text(version_notification, {
			software = software_name;
			current = event.current;
			latest = event.latest;
			url = render_url(version_url, { branch = branch, version = event.latest.latest });
		}));
		return;
	end

	if msg_latest and not have_notified(branch, "msg", msg_latest) then
		module:log_status("info", "New announcement");
		admin_notify(render_text(message_notification, {
			software = software_name;
			current = event.current;
			latest = event.latest;
			url = render_url(message_url, { branch = branch, message = msg_latest });
		}));
		return;
	end

	if not have_notified(branch, "support_status", event.latest.support_status) then
		if event.latest.support_status == "unsupported" then
			module:log_status("warn", "%s is no longer supported", branch);
			admin_notify(render_text(support_notification, {
				software = software_name;
				current = event.current;
				latest = event.latest;
				url = render_url(support_url, { branch = branch });
			}));
			return;
		end
	end
end);
