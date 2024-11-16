local http = require "prosody.net.http";
local json = require "prosody.util.json";
local promise = require "prosody.util.promise";

local health_report_api = module:get_option_string("health_report_api");
local auth_token = module:get_option_string("health_report_api_key");
local report_frequency = module:get_option_string("health_report_frequency", "hourly");

if not health_report_api or not auth_token then
	module:set_status("info", "Inactive - not configured");
	return;
end

local metric_registry = require "core.statsmanager".get_metric_registry();

local mod_audit_status = module:depends("audit_status");
local mod_measure_active_users = module:depends("measure_active_users");
local mod_snikket_version = module:depends("snikket_version");

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

local function get_gauge_metric(name)
	return (metric_registry.families[name].data:get(module.host) or {}).value;
end

function report_health()
	local url = health_report_api:gsub("DOMAIN", http.urlencode(module.host));

	mod_measure_active_users.update_calculations();

	local health = {
		launch_time = prosody.start_time;
		crashed = not not mod_audit_status.crashed;
		dau = get_gauge_metric("prosody_mod_measure_active_users/active_users_1d");
		wau = get_gauge_metric("prosody_mod_measure_active_users/active_users_7d");
		mau = get_gauge_metric("prosody_mod_measure_active_users/active_users_30d");
		version = mod_snikket_version.snikket_version;
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
		if response.code ~= 200 or response.headers["content-type"] ~= "application/json" then
			module:log("warn", "Health API error %d (%s)", response.code, response.headers["content-type"]);
			if response.headers["content-type"] == "application/json" then
				module:log("warn", "Error: %s", response.body);
			end
			return promise.reject("API error");
		end
		last_health_report = health;
		module:log("info", "Submitted health report");
	end)
	:catch(function (e)
		module:log("warn", "Failed to send health report: %s", e);
	end);


end

function module.ready()
	local secs = math.random(60, 90);
	module:log("debug", "Scheduled initial health report in %ds", secs);
	module:add_timer(secs, function ()
		report_health();
		module:cron({
			when = report_frequency;
			run = report_health;
		});
	end);
end

local pending_report = false;

function schedule_report_update()
	if pending_report then return; end
	module:add_timer(math.random(30, 60), function ()
		pending_report = false;
		report_health();
	end);
end

module:hook("client_management/new-client", schedule_report_update);
