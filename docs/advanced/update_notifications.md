# Update notifications

This is an informational technical document about the update notification
system in Snikket server.

## Why are update notifications important?

It is now widely known that [outdated software][OWASP-A9] is one of the
biggest risk factors in securing systems on the internet. Therefore the
Snikket server will alert all admins to available updates and important
notices from the Snikket team.

We believe it is up to you to decide when and how to update your service.
But we will provide you with the tools you need to make that easy, fast
and painless.

## How are they implemented?

To preserve your privacy, private Snikket servers do not make requests
directly to our servers. Instead we put the necessary information about
current releases and security updates into our DNS records.

## Why did you choose DNS?

The obvious choice was HTTP, and this is how most traffic on the internet
is conveyed these days. But we opted for DNS due to the following advantages:

- DNS is designed for serving small amounts of data from one place to many
- Due to caching, and its connectionless nature, DNS is more scalable
- Queries will often travel via an intermediate resolver, so we
    typically won't have access to your server's IP address
- A DNS query contains very little information, whereas HTTP will always
    leak the IP address, and by default will often leak other headers.

But it also has some known downsides. In particular DNS is not secure by
default. Intermediaries may observe or drop the query, or even modify the
response.

The following conclusions were made about the downsides:

- Observability: an intermediary seeing outbound queries to our DNS
    records may deduce that your server is running Snikket. This should
    not be a problem in itself - there are many ways to detect if a server
    is running Snikket (load up its web page for a start!).
- Availability: an intermediary may block queries for our DNS records.
    This would prevent a server admin from receiving update notifications,
    which is bad (they may be tricked into thinking they are up to date).
    However using another protocol such as HTTP(S) would not prevent this
    focused attack.
- Integrity: the data returned to the Snikket server may be modified or
    spoofed by an intermediary. This would allow them to trigger false
    update notifications. We have designed the system so that the risk is
    minimized - the update notifications will always include a link to the
    real announcement on snikket.org (if any). It is not possible to direct
    admins to arbitrary URLs.

It is possible that in the future we will add support for DNSSEC or manually
sign the data provided in our DNS records.

It is also possible that we will move to another mechanism in the future, if
a more suitable one can be found.

## The details

Snikket releases are organized into 'channels', e.g. 'dev', 'alpha', 'beta',
'stable'. Your server will work out the channel it belongs to, and make a DNS
query to:

```
TXT _channel.update.snikket.net
```

The response will look like:

```
"latest=3"
"secure=2"
"msg=0"
```

This response indicates that version '3' is the latest, but version '2' is the
last release with no known security vulnerabilities is '2'. The `msg` field
allows us to send important announcements that may not be included in a release.

A Snikket server will use the returned information to determine whether the
administrators need to be notified, and generate a message if necessary. Since
the server has no further information, the message will include a link to the
relevant announcement on the snikket.org website by calculating the URL to use.

## Disabling update checks

We strongly recommend you leave update notifications enabled so that you are
notified promptly about important releases and announcements. However if you
plan to receive these another way, you may disable them by adding to your
snikket.conf:

```
SNIKKET_UPDATE_CHECK=0
```

[OWASP-A9]: https://owasp.org/www-project-top-ten/2017/A9_2017-Using_Components_with_Known_Vulnerabilities
