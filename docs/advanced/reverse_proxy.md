---
title: Reverse proxies
---

# Running Snikket behind a reverse proxy

The default Snikket setup assumes that there is no other HTTP/HTTPS server
running. If you already have another web server running for example, you will
need to instruct it to forward Snikket traffic to Snikket.

!!! note

    A quick note about non-HTTP services. Snikket includes a number of non-HTTP
    services which cannot be routed through a HTTP reverse proxy. This includes
    XMPP, STUN and TURN. The documentation here applies to redirecting the HTTP
    and HTTPS ports (80 and 443) through a reverse proxy only.

# Certificates

It is important to get certificates correct when deploying Snikket behind a reverse
proxy. Snikket needs to obtain certificates from Let's Encrypt in order to secure
the non-HTTP services it provides. Be careful that your reverse proxy does not
intercept requests from Let's Encrypt that are intended for the Snikket service.

# Configuration

## Snikket

First we need to tell Snikket to use alternative ports, so that it doesn't conflict
with the primary web server/proxy that will be forwarding the traffic. This can be
done by adding the following lines to /etc/snikket/snikket.conf:

```
SNIKKET_TWEAK_HTTP_PORT=5080
SNIKKET_TWEAK_HTTPS_PORT=5443
```

You can choose any alternative ports that you would prefer, but the rest of this
documentation will assume you use the ports given in this example.

In the next step, you need to configure the web server to forward traffic to
Snikket on these ports. Follow the section below according to which web server
you are using.

## Web servers

Each web server is different, so here we provide some example configuration snippets
for the most common servers. Feel free to contribute any that you would like to see
included!

### Nginx

```
server {
  # Accept HTTP connections
  listen 80;
  listen [::]:80;

  server_name chat.example.com;
  server_name groups.chat.example.com;
  server_name share.chat.example.com;

  location / {
      proxy_pass http://localhost:5080/;
      proxy_set_header      Host              $host;
      proxy_set_header      X-Forwarded-For   $proxy_add_x_forwarded_for;

      # A bit of headroom over the 16MB accepted by Prosody.
      client_max_body_size 20M;
  }
}

server {
  # Accept HTTPS connections
  listen [::]:443 ssl ipv6only=on;
  listen 443 ssl;
  ssl_certificate /path/to/certificate.pem;
  ssl_certificate_key /path/to/key.pem;

  server_name chat.example.com;
  server_name groups.chat.example.com;
  server_name share.chat.example.com;

  location / {
      proxy_pass https://localhost:5443/;
      proxy_set_header      Host              $host;
      proxy_set_header      X-Forwarded-For   $proxy_add_x_forwarded_for;
      # REMOVE THIS IF YOU CHANGE `localhost` TO ANYTHING ELSE ABOVE
      proxy_ssl_verify      off;
      proxy_set_header      X-Forwarded-Proto https;
      proxy_ssl_server_name on;

      # A bit of headroom over the 16MB accepted by Prosody.
      client_max_body_size 20M;
  }
}
```

**Note:** You may modify the first server block to include a redirect to HTTPS
instead of proxying plain-text HTTP traffic. When doing that, take care to
proxy `.well-known/acme-challenge` even in plain text to allow Snikket to
obtain certificates.

### sslh

sslh is a little different to the other servers listed here, as it is not a web server. However it is able
to route encrypted traffic (such as HTTPS and even some kinds of XMPP traffic) to different places.

The snippet below lists the rules required to forward all of Snikket's traffic to Snikket. Don't forget that
Snikket will also need port 80 forwarded to 5080 somehow (otherwise it won't be able to obtain certificates).

Unlike the other solutions here, this approach also allows you to run encrypted XMPP through the HTTPS port.
To take full advantage of this feature, you will need to add additional DNS records. See [advanced DNS](dns.md)
for more information.

This configuration requires sslh 1.18 or higher.

```
listen:
(
    { host: "0.0.0.0"; port: "443"; },
);

protocols:
(
     ## Snikket rules
     # Send encrypted XMPP traffic directly to Snikket (this must be above the HTTPS rules)
     { name: "tls";     host: "127.0.0.1"; port: "5223"; alpn_protocols: [ "xmpp-client" ]; },
     # Send HTTPS traffic to Snikket's HTTPS port
     { name: "tls";     host: "127.0.0.1"; port: "5443"; sni_hostnames:  [ "chat.example.com", "groups.chat.example.com", "share.chat.example.com" ] },
     # Send unencrypted XMPP traffic to Snikket (will use STARTTLS)
     { name: "xmpp";    host: "127.0.0.1"; port: "5222"; },

     ## Other rules
     # Add rules here to forward any other hosts/protocols to non-Snikket destinations
);

```

### apache2

#### Basic

**Note**: enable the needed apache2 mods, if you have not already:
`a2enmod proxy proxy_http proxy_wstunnel ssl`


```
<VirtualHost *:80>

        ServerName  chat.example.com
        ServerAlias groups.chat.example.com
        ServerAlias share.chat.example.com

        ProxyPreserveHost On

        ProxyPass           / http://127.0.0.1:5080/
        ProxyPassReverse    / http://127.0.0.1:5080/

</VirtualHost>

<VirtualHost *:443>

        ServerName  chat.example.com
        ServerAlias groups.chat.example.com
        ServerAlias share.chat.example.com

        SSLEngine On
        SSLProxyEngine On
        ProxyPreserveHost On
        SSLProxyVerify None
        SSLProxyCheckPeerCN Off
        SSLProxyCheckPeerName Off

        SSLCertificateFile /path/to/certifolder/cert.pem
        SSLCertificateKeyFile /path/to/certifolder/privkey.pem
        SSLCertificateChainFile /path/to/certifolder/chain.pem

        ProxyPass           / https://127.0.0.1:5443/
        ProxyPassReverse    / https://127.0.0.1:5443/

</VirtualHost>

```
#### Advanced

The following configuration is for reverse proxying from another machine (other from the one hosting Snikket containers). If Snikket is running on the same machine as the reverse proxy, use the basic configuration instead.

<details>
	<summary>Click to show</summary>

A prerequisite is a mechanism to sync Snikket-managed letsencrypt TLS key and cert to `/opt/chat/letsencrypt`. This is required because Apache 2.4 is not able to revproxying based on SNI, routing encrypted TLS directly to the Snikket machine.
	
```
        <VirtualHost *:443>

                ServerName chat.example.com
                ServerAlias groups.chat.example.com
                ServerAlias share.chat.example.com

                ServerAdmin webmaster@localhost

                DocumentRoot /var/www/chat

                ErrorLog ${APACHE_LOG_DIR}/chat.example.com-ssl_error.log
                CustomLog ${APACHE_LOG_DIR}/chat.example.com-ssl_access.log combined

                SSLEngine on

                SSLCertificateFile /opt/chat/letsencrypt/chat.example.com/cert.pem
                SSLCertificateKeyFile /opt/chat/letsencrypt/chat.example.com/privkey.pem
                SSLCertificateChainFile /opt/chat/letsencrypt/chat.example.com/chain.pem

                SSLProxyEngine On
                ProxyPreserveHost On

                ProxyPass           / https://chat.example.com/
                ProxyPassReverse    / https://chat.example.com/

        </VirtualHost>

        <VirtualHost *:80>

                ServerName chat.example.com
                ServerAlias groups.chat.example.com
                ServerAlias share.chat.example.com

                ServerAdmin webmaster@localhost
                DocumentRoot /var/www/chat

                ProxyPreserveHost On

                ProxyPass           / http://chat.example.com/
                ProxyPassReverse    / http://chat.example.com/

                ErrorLog ${APACHE_LOG_DIR}/chat.example.com_error.log
                CustomLog ${APACHE_LOG_DIR}/chat.example.com_access.log combined

        </VirtualHost>

```
</details>

### Caddy
#### Basic
For a simple configuration that only proxies the Snikket web portal, the following Caddyfile can be used.
```
http://chat.example.com,
http://groups.chat.example.com,
http://share.chat.example.com {
	reverse_proxy localhost:5080
}

chat.example.com,
groups.chat.example.com,
share.chat.example.com {
	reverse_proxy https://localhost:5443 {
		transport http {
			tls_insecure_skip_verify
		}
	}
}
```

#### Advanced
<details>
  <summary>Click to show</summary>
The advanced configuration allows for Caddy to be used as a "multiplexer", that is, serving HTTPS and encrypted XMPP traffic through the same port. This can be used to get around some very restrictive firewalls, similar to [`sslh`](#sslh). The configuration also forwards port 80 to 5080 (which `sslh` cannot do). However, since Caddy, by design, is a layer 7 (HTTP) proxy, an additional layer 4 plugin is needed.

Download [xcaddy](https://github.com/caddyserver/xcaddy) and build Caddy with the [layer4](https://github.com/mholt/caddy-l4) plugin. Also include the [YAML plugin](https://github.com/abiosoft/caddy-yaml), since the layer4 plugin does not support Caddyfile ([yet](https://github.com/mholt/caddy-l4/issues/16)).
```bash
xcaddy build \
  --with github.com/mholt/caddy-l4 \
  --with github.com/abiosoft/caddy-yaml
```
Run Caddy with
```bash
caddy run --config config.yaml --adapter yaml
```

Alternatively, if you use Caddy with Docker, use the following Dockerfile. Make sure that the folder containing `config.yaml` is mounted as `/etc/caddy` inside the container.
```dockerfile
FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/mholt/caddy-l4 \
    --with github.com/abiosoft/caddy-yaml

FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

CMD ["caddy", "run", "--config", "/etc/caddy/config.yaml", "--adapter", "yaml"]
```
The `config.yaml` needs to
1. Forward HTTP traffic (on port 80) with Snikket hostnames to port 5080, and redirect other HTTP traffic to HTTPS. This is done by `srv1` in the example.
1. Forward HTTPS traffic (on port 443) with Snikket hostnames to port 5443 *without* terminating TLS, since Snikket obtains certificates by itself.
1. Forward encrypted XMPP traffic on port 443 to port 5223.
1. Forward unencrypted XMPP traffic on port 443 to port 5222 (which uses STARTTLS).
1. Forward the remaining traffic on port 443 to Caddy's standard HTTPS proxy.
1. Lastly, continue to run as a standard HTTP/S proxy.

```yaml
---
apps:
  layer4:             # layer4 plugin
    servers:
      srv0:
        listen:
        - ":443"      # the l4 plugin listens only on port 443
                      # for port 80 we use the http app
        routes:
        - match:
          - tls:      # match encrypted XMPP traffic
              alpn:
              - xmpp-client
          handle:
          - handler: proxy
            upstreams:
            - dial:   # and send to Snikket's encrypted XMPP port
              - localhost:5223
        - match:
          - tls:
              sni:    # match HTTPS traffic containing Snikket hostnames
              - chat.example.com
              - groups.chat.example.com
              - share.chat.example.com
          handle:
          - handler: proxy
            upstreams:
            - dial:   # and send to Snikket's HTTPS port
              - localhost:5443
        - match:
          - xmpp: {}  # match unencrypted XMPP traffic
          handle:
          - handler: proxy
            upstreams:
            - dial:   # and send to Snikket (will use STARTLS)
              - localhost:5222
        - handle:     # no `match` here, so it matches all leftover traffic
          - handler: proxy
            upstreams:
            - dial:   # send it to Caddy's HTTPS proxy, defined below
              - 127.0.0.1:1337
  http:
    https_port: 1337  # needed for HTTPS to work
    servers:
      srv1:
        listen:
        - ":80"       # handles Snikket HTTP traffic, and redirects
                      # other HTTP traffic to HTTPS
        routes:
          - match:
            - host:   # send Snikket's HTTP traffic to Snikket's HTTP port
                      # this is needed to let Snikket obtain certificates
              - chat.example.com
              - groups.chat.example.com
              - share.chat.example.com
            handle:
            - handler: subroute
              routes:
              - handle:
                - handler: reverse_proxy
                  upstreams:
                  - dial: localhost:5080
            terminal: true  # stop processing
          - handle:   # redirect leftover traffic to HTTPS
            - handler: static_response
              headers:
                Location:
                - https://{http.request.host}{http.request.uri}
      srv2:
        listen:
        - "127.0.0.1:1337"  # bind to localhost only
        routes:       # replace the below with your regular Caddy config (two standard examples are provided below)
        - match:      # this host will reverse proxy to port 1025
          - host:
            - reverse-proxy-1025.example.com
          handle:
          - handler: subroute
            routes:
            - handle:
              - handler: reverse_proxy
                upstreams:
                - dial: localhost:1025
          terminal: true
        - match:      # this host will proxy to port 1026
          - host:
            - reverse-proxy-1026.example.com
          handle:
          - handler: subroute
            routes:
            - handle:
              - handler: reverse_proxy
                upstreams:
                - dial: localhost:1026
          terminal: true
```
<br>In case you are using Docker, don't forget to [add the `host.docker.internal` extra host](https://stackoverflow.com/questions/48546124/what-is-linux-equivalent-of-host-docker-internal/61001152) and replace `localhost` with `host.docker.internal` in `config.yaml`.
</details>
