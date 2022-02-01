---
title: "Troubleshooting"
subtitle: Self-hosted Snikket troubleshooting
weight: 30
---

Problems with your Snikket setup? Don't worry! Most people don't experience
any issues, but if you do, it's likely something simple. This page describes
problems you might encounter, and how to solve them.

## General problems

### "Snikket is starting" page does not go away

If this page stays for more than a few minutes, there was probably an
issue obtaining certificates for your Snikket service. For more
information on diagnosing certificate issues, see the
['Certificates' section](#certificate-problems) later on this page.

### Unable to share large files

If you find that your users cannot share large files through Snikket,
there could be a couple of reasons:

- If you are using Snikket behind a reverse proxy, ensure that the proxy
  does not place a limit on the size of uploads. Check our [reverse proxy
  guide](../../advanced/reverse_proxy/) for more information.
- If the file is over 100MB, Snikket will attempt a direct device-to-device
  transfer. This requires you and your recipient to be online at the
  same time, and it only works between two users (not in groups). Also
  note that direct transfers are not currently supported to or from iOS
  devices.
- To share files over 100MB with a Snikket group or iOS users, we
  recommend a dedicated file transfer service. You can find a list of
  standalone [self-hosted file transfer services](https://github.com/awesome-selfhosted/awesome-selfhosted#file-transfer---single-click--drag-n-drop-upload), use a system
  such as NextCloud, or select one of the many free online file transfer
  services.

### Invitations are always expired

If all invitation links show as expired immediately after you create them:

- Check you copied the entire URL correctly.
- Ensure that you don't have an XMPP server or other service running on
  the same system as Snikket using port 5280.
- If you use a reverse proxy, check that it is correctly forwarding
  requests to Snikket. See our [reverse proxy guide](../../advanced/reverse_proxy/)
  for more info.

### Not responsible for this domain

If you see an error in the app reporting that the server is "not
responsible for this domain":

- Check that you do not have another XMPP server running on the same
  system as Snikket. It may be using the ports that Snikket needs.
- Check that your DNS setup is correct, and you do not have SRV records
  left over from a previous XMPP installation on the same domain. If you
  recently modified your DNS records, you may need to wait a while for
  DNS caches to expire the old records.

### Problems on Debian/Raspbian 10 ("buster") on Raspberry Pi or ARM devices

If you use Debian or Raspbian version 10 ("buster") on a Raspberry Pi or other
ARM-based system, you may experience Snikket's containers failing to start with
errors such as `"Operation Not Permitted"` or `"init_interp_main: can't initialize time"`.

#### Cause

Docker uses a system library called `libseccomp2` to isolate the main system
from the containers. The version of that system library shipped with Raspbian
Buster by default cannot handle certain time-related operations and it
unfortunately returns an error code which confuses the things attempting to
use it.

#### Solution

There are two options to fix this:

- You can upgrade your system to Raspbian (or Debian) 11 ("bullseye"). This will ship with a newer `libseccomp2` by default which does not have that issue.
- Alternatively, you can install an updated `libseccomp2` package from [backports](https://backports.debian.org/Instructions/) without upgrading your entire system. To do so, run:

   ```
   apt-get install libseccomp2/buster-backports
   ```

   If that command prints `E: Release 'buster-backports' for 'libseccomp2' was not found`
   or similar, you need to enable backports first. To do so, follow the [Instructions
   on the Debian Backports](https://backports.debian.org/Instructions/) page up
   to and including "Add Backports to sources.list". **Make sure to enter
   "buster-backports" and not "bullseye-backports" into your sources.list!**

   Now, you should be able to run the above command with success. You may have
   to restart the docker daemon or the containers after this, using:

   ```
   systemctl restart docker
   docker-compose up -d  # <- run this in your snikket directory
   ```

## Certificate problems

Certificates are an important part of securing connections to your
Snikket.

Snikket automatically obtains certificates from Let's Encrypt, and keeps
them up to date. This usually works without problems, but it can be
sensitive to a number of things that might cause it to fail.

### Common causes

Common causes of an inability to obtain or renew certificates:

#### Missing or incorrect DNS records

Snikket needs 3 DNS records to be added. Ensure you followed the steps
from the installation guide correctly, particularly the
[DNS configuration](https://snikket.org/service/quickstart/#step-1-dns).

If your server supports IPv6, you may also add that to DNS (using an
AAAA record). If you do this, you *must* tell Snikket by adding the
following line to your snikket.conf:

```
SNIKKET_TWEAK_IPV6=1
```

#### Port 80 blocked

Ensure that port 80 is open and accessible. You can review a [list of
ports required by Snikket](../../advanced/firewall/). Port 80 is required
to be open by Let's Encrypt so they can verify your domain.

On a VPS or in a cloud environment, your provider may require you to
manually open ports, e.g. in their web dashboard. If you are running in
a LAN, you may need to forward ports in your router's web interface.

Finally, check the firewall on the server itself (e.g. ufw, iptables or
nftables).

#### Incorrect reverse proxy configuration

If you have a reverse proxy set up (e.g. to run Snikket on the same server
as other websites or services), it needs to correctly forward requests
to Snikket on both http and https.

See our [Snikket reverse proxy documentation](../../advanced/reverse_proxy/)
for more information on correctly configuring reverse proxies.

### Certificate debugging commands

#### Checking for errors

If you think you have everything set up correctly and you're not sure what the
problem could be, check the error log:

```
cd /etc/snikket
docker-compose exec snikket_certs cat /var/log/letsencrypt/errors.log
```

If you get a "No such file or directory" error when running the above command,
inspect the debug log instead:

```
cd /etc/snikket
docker-compose exec snikket_certs cat /var/log/letsencrypt/letsencrypt.log | grep detail
```

#### Trying again

Once you have fixed any problems, you can force a new attempt with the
following command:

```
cd /etc/snikket
docker-compose exec snikket_certs /etc/cron.daily/certbot
```

If that command says that no certificates are due for renewal, but you need to
trigger a renewal anyway, run:

```
cd /etc/snikket
docker-compose exec snikket_certs su letsencrypt -- -c "certbot renew --config-dir /snikket/letsencrypt --cert-path /etc/ssl/certbot --force-renew"
```

Note that Let's Encrypt has strict [rate limits](https://letsencrypt.org/docs/rate-limits/) -
do not run these commands more often than necessary, or you may find yourself
unable to get new certificates for a while.
