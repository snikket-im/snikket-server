-- Before Snikket 20240109 we used a 'prosody:normal' role for "normal" user
-- accounts in Snikket. From this version we use "prosody:registered" instead.
-- As the default role was updated, this was transparent for most users.
-- However, some user accounts had the "prosody:normal" role explicitly
-- written to storage, and then it did not get updated to "prosody:registered".


local function do_migration(migrate_host)
	local role_store = assert(module:context(migrate_host):open_store("account_roles"));

	local migrated, failed, skipped = 0, 0, 0;
	-- Iterate all users
	for username in assert(role_store:users()) do
		local roles = role_store:get(username);

		if roles._default == "prosody:normal" then
			roles._default = "prosody:registered";
			if role_store:set(username, roles) then
				migrated = migrated + 1;
			else
				failed = failed + 1;
			end
		else
			skipped = skipped + 1;
		end
	end
	return migrated, failed, skipped;
end

function module.command(arg)
	if arg[1] == "migrate" then
		table.remove(arg, 1);
		local migrate_host = arg[1];
		if not migrate_host or not prosody.hosts[migrate_host] then
			print("EE: Please supply a valid host to migrate to the new role names");
			return 1;
		end

		-- Initialize storage layer
		require "prosody.core.storagemanager".initialize_host(migrate_host);

		print("II: Migrating roles...");
		local migrated, failed, skipped = do_migration(migrate_host);
		print(("II: %d migrated, %d failed, %d skipped"):format(migrated, failed, skipped));
		return (failed + skipped == 0) and 0 or 1;
	else
		print("EE: Unknown command: "..(arg[1] or "<none given>"));
		print("    Hint: try 'migrate'?");
	end
end
