local mime_map = module:shared("/*/http_files/mime").types or {
	css = "text/css",
	js = "application/javascript",
};

local libjs_path = module:get_option_string("libjs_path", "/usr/share/javascript");

module:provides("http", {
		default_path = "/share";
		route = {
			["GET /*"] = require "net.http.files".serve({ path = libjs_path, mime_map = mime_map });
		}
	});
