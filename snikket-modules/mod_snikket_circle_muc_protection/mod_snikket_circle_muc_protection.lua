--[[
The purpose of this module is to avoid accidental modification of the member
list by users.

With mod_authz_delegate enabled, snikket admins suddenly are granted ownership
on circle MUCs; while this is great for setting avatars, it is problematic
when considering that this also allows affiliation changes which would not be
reflected in the circle membership, causing all kinds of desyncs.

This is a first order solution to this challenge. Future solutions may allow
more modifications as well as synchronisation between MUC affiliation lists
and circle membership or stuff like that.

We want to get a release shipped which allows setting avatars first :-).
]]
local modulemanager = require"core.modulemanager";
local st = require "prosody.util.stanza";

local main_host_name = module:get_option("circle_muc_protection_main_domain");
local main_host_groups = nil;

local function get_groups_module()
	if main_host_groups then
		return main_host_groups;
	end

	module:log("debug", "lazy-initializing MUC protection module");
	if not main_host_name then
		return error("main host name required for circle MUC affiliation protection")
	end

	local target_module = modulemanager.get_module(main_host_name, "groups_internal");
	if not target_module then
		return error("groups_internal not available on "..main_host_name);
	end

	main_host_groups = target_module;
	return target_module;
end

local function get_muc_circle(muc_jid)
	for group_id in get_groups_module().groups() do
		local group_data = main_host_groups.get_info(group_id);
		if group_data.muc_jid == muc_jid then
			return group_id
		end
	end
	return nil
end

module:hook("muc-pre-set-affiliation", function(event)
	if event.actor == nil then
		module:log("debug", "affiliation change in %s granted because the actor is nil.", event.room.jid);
		return;
	end
	local group_id = get_muc_circle(event.room.jid);
	if group_id ~= nil then
		module:log("warn", "affiliation change blocked as %s is associated with circle %s", event.room.jid, group_id);
		event.allowed = false;
	else
		module:log("debug", "affiliation change not blocked as %s is not associated with any circle", event.room.jid);
	end
end);

module:hook("muc-pre-invite", function(event)
	local room = event.room;
	local group_id = get_muc_circle(room.jid);
	if group_id ~= nil then
		module:log("warn", "invite blocked as %s is associated with circle %s", room.jid, group_id);
		event.origin.send(st.error_reply(event.stanza, "cancel", "not-allowed", nil, room.jid));
		return true;
	else
		module:log("debug", "invite not blocked as %s is not associated with any circle", event.room.jid);
	end
end, -1);  -- run after the main members_only permission check
