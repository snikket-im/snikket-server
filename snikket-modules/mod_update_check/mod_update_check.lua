local adns = require "net.adns";
local r = adns.resolver();

local function dns_escape(input)
	return (input:gsub("%W", "_"));
end
local render_hostname = require "util.interpolation".new("%b{}", dns_escape);

local update_dns = module:get_option_string("update_check_dns");
local check_interval = module:get_option_number("update_check_interval", 86400);

local version_info = {};

do
	local version = prosody.version;
	local branch, bugfix = version:match("(%S+)%.(%d+)$");
	if branch then
		version_info.branch, version_info.level = branch, bugfix;
	end
end

function check_for_updates()
	r:lookup(function (records)
		local result = {};
		for _, record in ipairs(records) do
			local key, val = record.txt:match("(%S+)=(%S+)");
			if key then
				result[key] = val;
			end
		end
		module:fire_event("update-check/result", { result = result });
	end, render_hostname(update_dns, version_info), "TXT", "IN");
	return check_interval;
end

function module.load()
	module:add_timer(300, check_for_updates);
end

module:hook("update-check/result", function (event)
	local ver_secure = tonumber(event.result.secure);
	local ver_latest = tonumber(event.result.latest);
	local ver_installed = tonumber(version_info.level);

	if not ver_installed then
		module:log_status("warn", "Unable to determine local version number");
		return;
	end

	if ver_secure and ver_installed < ver_secure then
		module:log_status("warn", "Security update available!");
		return;
	end

	if ver_latest and ver_installed < ver_latest then
		module:log_status("info", "Update available!");
		return;
	end

	if event.result.support_status == "unsupported" then
		module:log_status("warn", "%s is no longer supported", version_info.branch);
		return;
	end
end);
