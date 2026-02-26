---
title: Advanced configuration
---

{{< lead >}}
In most situations, the configuration options shown in the example config in
[snikket-selfhosted](https://github.com/snikket-im/snikket-selfhosted/blob/main/snikket.conf.example) should suffice. In some cases of more complex requirements (such as running behind a [reverse proxy](reverse_proxy/)), it may be required to tweak more options. They are described here.
{{< /lead >}}

{{< panel style="warning" title="Note well" >}}
- **Some of these options may break your setup**

  Do not set them unless you know what you're doing. Particularly the options with `TWEAK` in their name are to be looked at carefully.

- Options *only* documented here may change their behaviour between releases without further notice

  There is no guarantee about any of the options documented *only* here. Some are experimental, some are reserved for specific uncommon use cases (for which the support may be dropped eventually), others only exist to glue Snikket components together and should not be touched at all.

Also, it is very likely not complete.
{{< /panel >}}

After modifying any options in snikket.conf, you must run 'docker compose up -d' to apply the changes.

## Configuration Option Reference

This reference is in no particular order. Most importantly, it is certainly not in the order of "things you should try to mess with come first".

### `SNIKKET_DOMAIN`

The domain name of your Snikket instance. Do not change this after it was once set.

### `SNIKKET_RETENTION_DAYS`

The number of days (as integer) for which your server should preserve messages so that all devices of a user can catch up, even if they end up being disconnected from the internet for a while.

The Snikket Server stores all messages which are sent to any user for the given number of days. As end-to-end encryption is used, no plaintext is generally stored, only encrypted messages. These messages are then decrypted only on the devices of the specific user.

It is recommended to set this number not too small. If a device is offline for longer than the number of days this option is set to, it will not receive all messages, which is generally a bad user experience. Note that it does no matter if any other device has received the messages: If a user has only a single device and is offline for more days than the retention period is set to, they will lose messages.

On the other hand, storing too many messages on the server causes impacts on server performance and data hygiene in general. The default of seven is considered reasonable in the sense that most users won't be offline for longer than that.

Changing this option to a lower value will delete messages from the server. Changing this option to a higher value will allow messages existing on the server to be retained for longer.

### `SNIKKET_UPLOAD_STORAGE_GB`

Use this option to place a limit on the amount of storage Snikket will use for files shared by users. You can use this to prevent your server's disk capacity being consumed if users upload many large files. By default there is no limit.

If the limit is reached, users will be unable to upload new files until older files are cleared by Snikket after the configured retention period (or the limit is increased).

Example:

```
# Allow no more than 1.5GB disk space to be used by uploaded files
SNIKKET_UPLOAD_STORAGE_GB=1.5
```

The amount of file storage used is affected by the configured retention period (7 days by default) - i.e. longer retention periods will mean files are stored for longer, and more space will be used. Take this into account when choosing a value.

### `SNIKKET_LOGLEVEL`

Control the detail level of the log output of the snikket server.

Valid options are `error`, `warn`, `info` (the default) and `debug`. The `debug` log level is very detailed. It may quickly fill your disk and also contain more sensitive information.

### `SNIKKET_SITE_NAME`

A human-friendly name for your server. Defaults to the value of `SNIKKET_DOMAIN`.

### `SNIKKET_UPDATE_CHECK`

By default, Snikket sends anonymous requests for the latest release via DNS, to provide you with a notification when a new release is available (which may contain important security fixes). This behaviour can be disabled by setting the option to `0`.

This will not expose your server's IP address or domain name to the Snikket org, as it will generally be proxied through your or your hosters Internet Service Provider's DNS servers.

### `SNIKKET_ADMIN_EMAIL`

Email address of the admin. This will be sent to all new users as contact information.

### `SNIKKET_ABUSE_EMAIL`

Optional. **Public.** Email address to which people should send abuse reports. It will be publicly visible to the XMPP network and on the instance website.

### `SNIKKET_SECURITY_EMAIL`

Optional. **Public.** Email address to which people should send security reports. It will be publicly visible to the XMPP network and on the instance website.

### `SNIKKET_TLS_PROFILE`

Specify the TLS profile to use for chat connections. You only need this if you
have trouble connecting some older devices to connect to your server.

Valid options:

- `modern` - the default, strongest security. Compatible with Android 10+, iOS 12+.
- `intermediate` - wide compatibility with older devices, high security level
- `old` - compatibility with very old devices, not generally recommended

The profiles are based on [Mozilla's server-side TLS profiles](https://wiki.mozilla.org/Security/Server_Side_TLS).

### `SNIKKET_WEB_AVATAR_CACHE_TTL`

The time (in seconds) for which the web portal will allow avatars to be cached by browsers.

### `SNIKKET_PROXY65_PORT`

The port to use for the internal file transfer proxy (used for transferring large files).
Defaults to port 5000, but can be changed if something else is using this port (the apps
will automatically discover the configured port). Don't forget to update your firewall
rules if you change this.

## Advanced Configuration Reference

It should generally not be necessary to use the options in this section. These
options have a high chance of breaking your Snikket setup (sometimes in subtle
ways) or reducing security, if used incorrectly.

### `SNIKKET_CERTBOT_OPTIONS`

Add extra options to the certbot command-line.

### `SNIKKET_CERTBOT_KEY_OPTIONS`

Defaults to `--reuse-key`. Set to `--no-reuse-key` to rotate the private key
on every certificate renewal. Note that rotating the key may invalidate things
that depend on a stable public key, such as DANE and certificate monitoring
utilities.

### `SNIKKET_TWEAK_TURNSERVER_PORT`

Controls the primary listening port of the TURN server (default: 3478).

This option is used to select the port that clients should use for STUN/TURN.

If using the built-in TURN server, the TURN server will automatically listen
on the selected port.

If you are using an external TURN server, make sure this option is set to the
port that your TURN server is using (3478 is the default if unset).

### `SNIKKET_TWEAK_TURNSERVER_MIN_PORT`

Controls the lowest port number used for TURN relay services.

See [the firewall docs](../firewall) for details.

### `SNIKKET_TWEAK_TURNSERVER_MAX_PORT`

Controls the highest port number used for TURN relay services.

See [the firewall docs](../firewall) for details.


## Arcane Configuration Reference

**The options below this line are even more arcane than the options above. Do not touch unless you truly know what you're doing.**

### `SNIKKET_TWEAK_INTERNAL_HTTP_PORT`

The TCP port on which the internal HTTP API listens on. The default is `5280`. Do not change this without also changing `SNIKKET_WEB_PROSODY_ENDPOINT` accordingly.

### `SNIKKET_TWEAK_INTERNAL_HTTP_INTERFACE`

The IP address on which the internal HTTP API listens on. The default is `127.0.0.1`, so that the API is only accessible from the same server. Changing this may be a security risk as some general system information is accessible without authentication.

### `SNIKKET_TWEAK_HTTP_TLS_VERSIONS`

The TLS versions to offer for HTTPS. Changing this may make your setup less
secure, or else prevent some browsers or operating systems from connecting to
your instance.

By default we follow Mozilla's TLS 'intermediate' profile, which balances
strong security with allowing a range of browsers and clients to connect.

To follow Mozilla's 'strict' profile (which may cause connectivity issues with
Android < 9, Windows < 11, Safari/iOS < 12, and others), set:

```
SNIKKET_TWEAK_HTTP_TLS_VERSIONS=TLSv1.3
SNIKKET_TWEAK_HTTP_TLS_CIPHERS=
```

### `SNIKKET_TWEAK_HTTP_TLS_CIPHERS`

The TLS ciphers to offer for HTTPS. See the previous option about TLS version
configuration for more details.

### `SNIKKET_TWEAK_WEB_PROXY_PROTOCOLS`

This is for customization of the web proxy configuration. After adding new
configuration templates, this can be used to load them, it's a list of
space-separated names.

Defaults to `http https`.

### `SNIKKET_TWEAK_WEB_PROXY_RELOAD_INTERVAL`

The number of seconds between reloads of the web proxy (i.e. to pick up new
certificates). Specified as a number of seconds, or `inf` to disable reloads.

### `SNIKKET_INVITE_URL`

The URL template for invitation links. The server needs to know under which address the invitation service is hosted.

Changing this will most likely break your invitation flow, so better don't.

### `TWEAK_SNIKKET_BOOTSTRAP_INDEX`

Just do not set this.

### `TWEAK_SNIKKET_BOOTSTRAP_SECRET`

Also better do not set this.

### `SNIKKET_TWEAK_IPV6`

Disable IPv6 support by setting to `0`.

By default, IPv6 is enabled because Snikket uses host networking and gracefully handles IPv6 hosts being unreachable.

### `SNIKKET_TWEAK_PROMETHEUS`

If you are monitoring your Snikket server using [Prometheus](https://prometheus.io/) and scraping the metrics endpoint, you should set this to `1` and let it at its default otherwise.

If this is set to `1` without Snikket server being scraped by Prometheus, the System Health panel in the web portal will not work correctly. If this is not set to `1` when Snikket is being scraped by Prometheus, the numbers seen by Prometheus may not be accurate at the time they are being sampled, as Snikket server will in that case sample data only every 60s, no matter how often or when you scrape.

The default is safe for non-Prometheus setups.

### `SNIKKET_TWEAK_TURNSERVER`

By default, Snikket starts a STUN/TURN server. If this option is set to `0`, it will not do that. You will have to run your own STUN/TURN server and configure `SNIKKET_TWEAK_TURNSERVER_DOMAIN` and `SNIKKET_TWEAK_TURNSERVER_SECRET` accordingly.

If `SNIKKET_TWEAK_TURNSERVER` is set to `0` and `SNIKKET_TWEAK_TURNSERVER_DOMAIN` is not set, no STUN/TURN server will be offered to your users. Terrible idea to do that, will break audio/video calls in all but the most ideal situations.

### `SNIKKET_TWEAK_TURNSERVER_DOMAIN`

Hostname of the STUN/TURN server to use.

Defaults to the Snikket domain, as snikket-server runs contains its own STUN/TURN server.

### `SNIKKET_TWEAK_TURNSERVER_SECRET`

Shared secret to use with the STUN/TURN server for authentication of clients.

Defaults to a secret which is generated once at first installation. Only override this if you also set `SNIKKET_TWEAK_TURNSERVER` to `0` and set `SNIKKET_TWEAK_TURNSERVER_DOMAIN` to a STUN/TURN server you operate manually.

### `SNIKKET_TWEAK_SHARE_DOMAIN`

Expose the file share service at the `SNIKKET_DOMAIN` instead of at `share.SNIKKET_DOMAIN`.

This nowadays conflicts with the web portal, so you should not set it.

### `SNIKKET_TWEAK_GENERAL_MUC`

Config for the deprecated general MUC (if it exists). Can be `hidden` or
`destroyed`. Defaults to `hidden`.

### `SNIKKET_TWEAK_DNSSEC`

Enable DNSSEC support. Requires a DNSSEC-capable resolver.
This also enables DANE for outgoing connections.

### `SNIKKET_TWEAK_EXTRA_CONFIG`

Path or glob for extra configuration files to load.

### `SNIKKET_TWEAK_STORAGE`

Sneak preview of SQLite storage. Valid values are `files` (the default) and `sqlite` (potential future default).

### `SNIKKET_TWEAK_PUSH2`

Preview of "Push 2.0", a planned upgrade to how push notifications currently
work. This is not yet supported by any clients, the specification is still
being worked on, and this toggle is only to enable developers to test against
the prototype.

When set to `1` support for Push 2.0 will be enabled.

### `SNIKKET_TWEAK_REQUIRE_SASL2`

When set to `1` this will disable support for legacy SASL, requiring all
clients to support SASL2. We plan for this to be the default in the future due
to increased security, speed and other features, but currently there are many
apps without SASL2 support and this would prevent them connecting.

The tweak is available now so developers can ensure their client will work in
SASL2-only mode, or admins can disable legacy SASL early if they are certain
of only using SASL2-capable clients.

### `SNIKKET_TWEAK_RESTRICTED_USERS_V2`

When set to `1` this will enable an alternative implementation of "restricted
users". It is primarily for testing the implementation that is expected to
become the default in a future release.

### `SNIKKET_TWEAK_S2S_STATUS`

When set to `1` this will enable a module that monitors the list and health of
server-to-server connections. This is only useful for developers, as the
information cannot currently be viewed in the user interface.
