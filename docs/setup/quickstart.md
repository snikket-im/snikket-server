---
title: "Quick-start guide"
date: 2020-01-14T16:32:02Z
---

# Introduction

Hi, welcome! This is a guide to help you set up your own [Snikket service](/service/). Once it is set up,
you will be able to invite others to join you using the [Snikket app](/app/) and chat over your own
private messaging server!

Right, let's get started...

!!! warning

    Heads up! Snikket is currently in its early stages (we launched at FOSDEM 2020!). Although you can
    use Snikket today, there are many features that are still to come, and we're working on improving the setup
    experience.
    
    If you have any questions, feedback, or words of encouragement, we'd love to hear from you! Email us at
    feedback@snikket.org.

## Requirements

To follow this guide you will need:

 - A server running Linux that you have SSH or terminal access to
 - A domain name that you can create subdomains on

For the server, you can use a VPS from a provider such as [DigitalOcean](https://digitalocean.com/) (you can use this [referral link for $100 credit](https://m.do.co/c/3ade5a32d0e0)),
or you can use a physical device such as a Raspberry Pi. Note that if you run your server at home (which is _really_ cool!) you may need to forward some ports on your
router.

{{< infobox warning >}}
**Important:** Snikket provides a built-in web server that must be accessible on port 80. Therefore this guide assumes you are _not_ running any existing
websites on the same server. We are working to remove this requirement in a future version.
{{< /infobox >}}

## Get Started

### Step 1: DNS

First you need to find your server's public ("external") IP address. If you are using a hosted server, this may be shown in your management dashboard.
At a pinch you can use an online service, e.g. by running `curl -4 ifconfig.co` in your terminal.

Now, add an A record for your IP address on the domain you want to run Snikket on. In the examples I'm going to use 'chat.example.com' as the domain,
and '10.0.0.2' as the IP address. This will be the primary domain for your Snikket service.

```
# Domain           TTL  Class  Type  Target
chat.example.com.  300  IN     A     10.0.0.2
```

How to add records depends on where your DNS is hosted. Here are links to guides for a few common providers:

- [GoDaddy](https://uk.godaddy.com/help/add-an-a-record-19238)
- [Gandi](https://docs.gandi.net/en/domain_names/faq/record_types/a_record.html)
- [Namecheap](https://www.namecheap.com/support/knowledgebase/article.aspx/319/2237/how-can-i-set-up-an-a-address-record-for-my-domain)

**Tip:** If you have an IPv6 address too, this is where you can add it - simply make another record for `chat.example.com.` with the record
type `AAAA` and put your IPv6 address as the target.

Now that you have an A record, you also need a couple more records. To avoid repeating the IP address everywhere, we'll use CNAME records,
which are just like aliases of the main domain:

```
# Domain            TTL  Class  Type   Target
groups.chat.example.com  300  IN     CNAME  chat.example.com.
share.chat.example.com   300  IN     CNAME  chat.example.com.
```

These subdomains provide group chat functionality and file-sharing respectively.

### Step 2: Docker

Docker is a handy tool for running self-contained services known as "containers". We use Docker to provide Snikket
in a clean way that works reliably across all different systems.

If you have the `docker` and `docker-compose` commands already available on your system, great! You can skip to Step 3 below. If not, continue reading.

#### docker

Getting docker up and running can vary depending on what OS you're running. Luckily Docker provides an installation guide
for a range of operating systems. Follow the guide for your system:

- [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/)
- [Debian](https://docs.docker.com/install/linux/docker-ce/debian/)
- [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/)
- [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

#### docker-compose

The Docker folks also provide a handy tool called `docker-compose` which is not installed by default. We're going to use it
as an easy way to launch and configure Snikket.

As per the [installation instructions](https://docs.docker.com/compose/install/) (see the 'Linux' tab there), install
`docker-compose` with the following commands:

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod a+x /usr/local/bin/docker-compose
```

### Step 3: Prepare for Snikket!

This is exciting, we're so close!

Create a configuration directory and switch to it:

```
mkdir /etc/snikket
cd /etc/snikket
```

And then create a new file there called `docker-compose.yml` using a text editor (such as nano, or vim).

```
nano docker-compose.yml
```

And here is what you should put in the file:

```
version: "3.3"

services:
  snikket:
    container_name: snikket
    image: snikket/snikket:alpha
    env_file: snikket.conf
    restart: unless-stopped
    network_mode: host
    volumes:
      - snikket_data:/snikket

volumes:
  snikket_data:
```

Now create another file in the same directory, `snikket.conf` with the following contents:

```
# The primary domain of your Snikket instance
SNIKKET_DOMAIN=chat.example.com

# An email address where the admin can be contacted
# (also used to register your Let's Encrypt account to obtain certificates)
SNIKKET_ADMIN_EMAIL=you@example.com
```

Change the values to match your setup.

### Step 4: Launch

Here we go! Run:

```
docker-compose up -d
```

The first time you run this command docker will download Snikket. In a moment it should complete,
and Snikket should be running.

Now to set up your first account. To create yourself an admin account, run the following command:

```
docker exec snikket create-invite --admin
```

Follow the link to open the invitation, and follow the instructions get signed in.

You can create as many links as you want and share them with people. Each link can
only be used once. Don't forget to drop the `--admin` part to create normal user accounts!

{{< infobox primary >}}
That's it! How did it go? Let us know at feedback@snikket.org
{{< /infobox >}}
