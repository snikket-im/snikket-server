local http = require "prosody.net.http";
local json = require "prosody.util.json";
local promise = require "prosody.util.promise";

local health_report_api = module:get_option_string("health_report_api");
local auth_token = module:get_option_string("health_report_api_key");

if not health_report_api or not auth_token then
	module:set_status("info", "Inactive - not configured");
	return;
end

local metric_registry = require "core.statsmanager".get_metric_registry();

local mod_audit_status = module:depends("audit_status");

local last_health_report;

local function has_changed(new, old)
	if old == nil then return true; end
	for k, v in pairs(new) do
		if v ~= old[k] then
			return true;
		end
	end
	return false;
end

function get_gauge_metric(name)
	return (metric_registry.families[name].data:get(module.host) or {}).value;
end

function report_health()
	local url = health_report_api:gsub("DOMAIN", http.urlencode(module.host));

	local health = {
		launch_time = prosody.start_time;
		crashed = not not mod_audit_status.crashed;
		dau = get_gauge_metric("prosody_mod_measure_active_users/active_users_1d");
		wau = get_gauge_metric("prosody_mod_measure_active_users/active_users_7d");
		mau = get_gauge_metric("prosody_mod_measure_active_users/active_users_30d");
		version = prosody.version;
	};

	if not has_changed(health, last_health_report) then
		return;
	end

	http.request(url, {
		headers = {
			["Content-Type"] = "application/json";
			["Authorization"] = "Bearer "..auth_token;
		};
		body = json.encode(health);
	}):next(function (response)
		if response.code ~= 200 or response.headers.content_type ~= "application/json" then
			module:log("warn", "Health API error %d (%s)", response.code, response.headers.content_type);
			return promise.reject();
		end
		last_health_report = health;
		module:log("info", "Submitted health report");
	end)
	:catch(function ()
		module:log("warn", "Failed to send health report");
	end);


end

function module.ready()
	local secs = math.random(60, 90);
	module:log("debug", "Scheduled initial health report in %ds", secs);
	module:add_timer(secs, function ()
		report_health();
		module:daily(report_health);
	end);
end
