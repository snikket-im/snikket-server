local dt = require "util.datetime";
local http = require "net.http";
local json = require "util.json";
local promise = require "util.promise";
local st = require "util.stanza";

local billing_api = module:get_option_string("snikket_billing_api");
local billing_dashboard_url = module:get_option_string("snikket_billing_dashboard");
local billing_message = module:get_option_string("snikket_billing_message",
	"Payment required. Please review your details at "..billing_dashboard_url
);

local billing_min_retry_time = module:get_option_number("snikket_billing_min_retry_time", 3600);
local billing_unverified_grace_period = module:get_option_number("snikket_billing_unverified_grace_period",
	billing_min_retry_time * 3.5
);
local billing_grace_period = module:get_option_number("snikket_billing_grace_period", 86400 * 1.1);
local billing_spread_factor = module:get_option_number("snikket_billing_spread_factor", 0.20);

local unrestricted_remote_domains = module:get_option_set("snikket_billing_unrestricted_remote_domains", {});

if not billing_api then return; end -- Billing not activated

--- Code to respond to billing status changes

local current_status = "unverified";
local features = {};
local last_status_change = os.time() - 60;

function handle_billing_info(event)
	local billing_info = event.billing_info;
	local new_status = billing_info.status;

	if new_status ~= "unverified" then
		features = billing_info.features or {};
	end

	if new_status == current_status then
		return; -- Nothing to do
	end

	-- Status changed
	current_status = billing_info.status;
	module:fire_event("snikket-billing-status-changed");
end

module:hook("snikket-billing-updated", handle_billing_info);

module:add_timer(billing_unverified_grace_period, function ()
	if current_status == "unverified" and (os.time() - last_status_change) >= billing_unverified_grace_period then
		module:log("warn", "Unable to verify billing status - entering inactive state");
		current_status = "inactive";
		last_status_change = os.time();
		module:fire_event("snikket-billing-status-changed");
	end
end);

module:hook("stanza/urn:ietf:params:xml:ns:xmpp-sasl:auth", function(event)
	if current_status == "inactive" then
		local reply = st.stanza("failure", { xmlns = "urn:ietf:params:xml:ns:xmpp-sasl" })
			:tag("account-disabled"):up()
			:text_tag("text", billing_message);
		event.origin.send(reply);
	end
end, 100);

module:hook_tag("urn:xmpp:sasl:2", "authenticate", function (session)
	if current_status == "inactive" then
		local reply = st.stanza("failure", { xmlns = "urn:xmpp:sasl:2" })
			:tag("account-disabled", { xmlns = "urn:ietf:params:xml:ns:xmpp-sasl" }):up()
			:text_tag("text", billing_message);
		session.send(reply);
	end
end);

-- Allow restricting federation for trial instances, to prevent their use for spam and abuse
do
	local is_user_subscribed = require "core.rostermanager".is_user_subscribed;
	local jid_host = require "util.jid".host;
	module:hook("route/remote", function (event)
		if features.federation ~= "restricted" then return; end
		local origin, stanza = event.origin, event.stanza;
		if stanza.name == "iq" then return; end
		if is_user_subscribed(origin.username, origin.host, stanza.attr.to) then
			return; -- Allow to contacts that have authorized the sender
		end
		if unrestricted_remote_domains:contains(jid_host(stanza.attr.to)) then
			return;
		end
		-- Found no reason to permit, so bounce an error
		local err_msg;
		if features.trial then
			err_msg = "Communication with other domains is restricted during the trial period";
		else
			err_msg = "Communication with other domains is currently restricted on this instance";
		end
		origin.send(st.error_reply(stanza, "cancel", "policy-violation", err_msg));
		return true;
	end);
end

--- Code to update the billing status

local billing_info;

local function spread(base, fraction)
	return base * ( (1 - (fraction * 2)) + ( (fraction * 2) * math.random() ) );
end

function update_billing_info()
	local url = billing_api:gsub("DOMAIN", http.urlencode(module.host));

	http.request(url)
		:next(function (response)
			if response.code ~= 200 or response.headers.content_type ~= "application/json" then
				module:log("warn", "Billing API error %d (%s)", response.code, response.headers.content_type);
				return promise.reject();
			end
			local new_billing_info = json.decode(response.body);
			if type(new_billing_info) ~= "table" then
				module:log("warn", "Invalid data received from billing API (%s)", type(new_billing_info));
				return promise.reject();
			end

			new_billing_info.received = os.time();
			if new_billing_info.expiry then
				if type(new_billing_info.expiry) == "string" then
					new_billing_info.expiry = dt.parse(new_billing_info.expiry);
					if not new_billing_info.expiry then
						return promise.reject();
					end
				end
			end

			local old_billing_info = billing_info;
			billing_info = new_billing_info;

			if not old_billing_info or old_billing_info.status ~= new_billing_info.status then
				module:fire_event("snikket-billing-updated", {
					billing_info = billing_info;
				});
			end

			local next_update_secs = math.max((billing_info.expiry + billing_grace_period) - os.time(), billing_min_retry_time);
			module:add_timer(spread(next_update_secs, billing_spread_factor), update_billing_info);
		end)
		:catch(function ()
			local secs = spread(billing_min_retry_time, billing_spread_factor);
			module:log("warn", "Failed to fetch billing status - retry in %0.2f seconds", secs);
			module:add_timer(secs, update_billing_info);
		end);
end

