#!/usr/bin/lua

local url = require "socket.url";

for smtp_url in io.lines() do
	local parsed_url = url.parse(smtp_url);
	print("# "..smtp_url);
	for k, v in pairs(parsed_url) do print("# "..k.." = "..v) end
	print ""

	local protocol = parsed_url.scheme or "smtp";
	local default_port = (protocol == "smtps" and 465) or 25;

	print("account default");
	print(("host %s"):format(parsed_url.host));
	print(("port %d"):format(parsed_url.port or default_port));

	if parsed_url.params ~= "no-tls" then
		local verify_cert = parsed_url.params ~= "insecure";

		print("tls on");
		if verify_cert then
			print("tls_trust_file /etc/ssl/certs/ca-certificates.crt");
		else
			print("tls_trust_file"); -- empty disables trust verification
			print("tls_certcheck off");
		end
		if protocol == "smtps" then
			print("tls_starttls off");
		end
	end

	if parsed_url.user then
		print("auth on");
		print(("user %s"):format(parsed_url.user));
	end
	if parsed_url.password then
		print(("password %s"):format(parsed_url.password));
	end
end
