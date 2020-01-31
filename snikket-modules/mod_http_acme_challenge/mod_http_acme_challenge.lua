local serve = require "net.http.files".serve;

module:set_global();

local path = module:get_option_string("acme_challenge_path", "/var/www/.well-known/acme-challenge");

module:provides("http", {
		default_path = "/.well-known/acme-challenge";
		route = {
			["GET /*"] = serve({ path = path });
		}
	});
