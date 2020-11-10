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
	local record_name = render_hostname(update_dns, version_info);
	module:log("debug", "Checking for updates on %s...", record_name);
	r:lookup(function (records)
		if not records or #records == 0 then
			module:log("warn", "Update check failed");
			return;
		end
		local result = {};
		for _, record in ipairs(records) do
			if record.txt then
				local key, val = record.txt:match("(%S+)=(%S+)");
				if key then
					result[key] = val;
				end
			end
		end
		module:log("debug", "Finished checking for updates");
		module:fire_event("update-check/result", { current = version_info, latest = result });
	end, record_name, "TXT", "IN");
	return check_interval;
end

function module.load()
	module:add_timer(5, check_for_updates);
end
