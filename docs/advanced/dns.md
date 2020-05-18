---
title: Advanced DNS setup
---

The quick start guide helps you set up the essential DNS records for your Snikket
service. There are a few additional records you can add to unlock some features
of your Snikket service.

## Hosting on alternative XMPP ports

The default XMPP ports are:

- 5222 (for connections from the app and other XMPP clients)
- 5269 (for connections from other Snikket/XMPP servers, i.e. federation)

If you want to change these, you can add a type of DNS record called SRV records.

Unfortunately SRV records setup varies widely between different DNS providers, so
you'll need to figure out which info to put where yourself, based on the example
records shown here.

An SRV record to override the client port looks like this:

```
_xmpp-client._tcp.chat.example.com. 18000 IN SRV 0 0 5222 chat.example.com.
```

While an SRV record to override the server-to-server port looks like this:

```
_xmpp-server._tcp.chat.example.com. 18000 IN SRV 0 0 5269 chat.example.com.
```

## Client connections through HTTPS port

It's possible to enable the client to connect through port 443 (the HTTPS port), which
can allow bypassing some very restrictive firewalls.

Firstly, you need to set up sslh, as described in the [reverse proxy](reverse_proxy.md#sslh)
documentation. Then you need to add the following SRV record:

```
_xmpps-client._tcp.chat.example.com. 86400 IN SRV 5 0 443  chat.example.com.
```

Note the 's' in `_xmpps-client`! The other differences in this record are that we set the port
to 443 (the HTTPS port), and the priority to '5', so that clients supporting this connection
method will prefer it over other connection methods (we specified priority '0' in the `_xmpp-client`
example above).
