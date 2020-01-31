local mime_map = module:shared("/*/http_files/mime").types or {
	css = "text/css",
	js = "application/javascript",
};

module:provides("http", {
		default_path = "/share";
		route = {
			["GET /*"] = require "net.http.files".serve({ path = "/usr/share/javascript", mime_map = mime_map });
		}
	});
