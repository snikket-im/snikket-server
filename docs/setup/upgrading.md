---
title: "Upgrading your Snikket server"
date: 2021-05-19T14:32:02Z
---

Upgrading to a new Snikket release is typically very easy.

## snikket-selfhosted

If you installed Snikket using the [snikket-selfhosted][] scripts, simply run:

    cd /opt/snikket
    git pull
    ./scripts/update.sh

## Snikket quickstart

If you're using a version installed from the [original quickstart][] guide on
the website, use these commands instead:

    cd /etc/snikket
    docker-compose pull
    docker-compose up -d

[snikket-selfhosted]: https://github.com/snikket-im/snikket-selfhosted
[original quickstart]: https://snikket.org/service/quickstart/
