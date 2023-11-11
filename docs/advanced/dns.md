---
title: Client connections through HTTPS port
---

It's possible to enable the client to connect through port 443 (the HTTPS port), which
can allow bypassing some very restrictive firewalls.

Firstly, you need to set up sslh, as described in the [reverse proxy](reverse_proxy.md#sslh)
documentation. Then you need to add the following SRV record:

```
_xmpps-client._tcp.chat.example.com. 86400 IN SRV 0 0 443  chat.example.com.
```
Unfortunately SRV records setup varies widely between different DNS providers, so
you'll need to figure out which info to put where yourself, based on the example
records shown here.
