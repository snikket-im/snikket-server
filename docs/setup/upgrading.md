---
title: Upgrading your Snikket instance
linktitle: Upgrading
description: "Upgrading your Snikket instance is easy."
date: 2021-05-19T14:32:02Z
weight: 20
---

We periodically announce new releases of the Snikket server software on our
[blog][], [Mastodon][] and [Twitter][]. You will also receive [update
notifications][] directly from your instance when it is time to upgrade.

Upgrading to a new Snikket release is typically very easy. The correct process
to use depends on the method you initially used to set up your Snikket
instance. Each method is explained here.


{{< panel style="warning" >}}
**Compatibility notes**

If your system matches *any* of the following descriptions, please check
the [host system compatibility](../troubleshooting/#host-compatibility)
section of the troubleshooting guide before you upgrade:

- ARM or Raspberry Pi devices running Debian or Raspbian 10 ("buster") or older
- Docker version 20.10.9 or earlier
{{< /panel >}}

## Upgrading

### Snikket quick-start

If you are using a version installed from the [original quick-start][] guide
on the website (most likely), then use these commands:

```
    cd /etc/snikket
    docker-compose pull
    docker-compose up -d
```

### snikket-selfhosted

If you installed Snikket using the [snikket-selfhosted][] repository, simply
run:

```
    cd /opt/snikket
    git pull
    ./scripts/update.sh
```

### Snikket hosting

If you're using our hosting service, you can upgrade by visiting your
[hosting dashboard][] and clicking the 'Update' button next to your instance.

**Note:** Updates are not always available on the hosted platform immediately
after release. If the 'Update' button is not present, try again later.
Typically you will receive a notification when an update is available.

## Check your version

There are several ways to check the version of the Snikket server you are
currently using:

### Using the web interface

1. Log into the web interface using your admin account
2. In the footer of the page click on "Snikket service"
3. Scroll to the section "Software versions"

### Using the command-line

SSH into the system where Snikket is installed, and run the following command:

```shell
docker exec snikket prosodyctl about | head -n1
```

[snikket-selfhosted]: https://github.com/snikket-im/snikket-selfhosted
[original quick-start]: https://snikket.org/service/quickstart/
[hosting dashboard]: https://my.snikket.org/
[blog]: https://snikket.org/blog/
[Mastodon]: https://fosstodon.org/@snikket_im
[Twitter]: https://twitter.com/snikket_im
[update notifications]: ../../advanced/update_notifications/
