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

After modifying any options in snikket.conf, you must run 'docker-compose up -d' to apply the changes.

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

### `SNIKKET_WEB_AVATAR_CACHE_TTL`

The time (in seconds) for which the web portal will allow avatars to be cached by browsers.

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

### `SNIKKET_TWEAK_TURNSERVER_MIN_PORT`

Controls the lowest port number used for TURN relay services.

See [the firewall docs](firewall.md) for details.

### `SNIKKET_TWEAK_TURNSERVER_MAX_PORT`

Controls the highest port number used for TURN relay services.

See [the firewall docs](firewall.md) for details.


## Arcane Configuration Reference

**The options below this line are even more arcane than the options above. Do not touch unless you truly know what you're doing.**

### `SNIKKET_TWEAK_INTERNAL_HTTP_PORT`

The TCP port on which the internal HTTP API listens on. The default is `5280`. Do not change this without also changing `SNIKKET_WEB_PROSODY_ENDPOINT` accordingly.

### `SNIKKET_TWEAK_INTERNAL_HTTP_INTERFACE`

The IP address on which the internal HTTP API listens on. The default is `127.0.0.1`, so that the API is only accessible from the same server. Changing this may be a security risk as some general system information is accessible without authentication.

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

### `SNIKKET_TWEAK_DNSSEC`

Enable DNSSEC support. Requires a DNSSEC-capable resolver.
This also enables DANE for outgoing connections.

### `SNIKKET_TWEAK_EXTRA_CONFIG`

Path or glob for extra configuration files to load.
