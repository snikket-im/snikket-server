---
title: Firewall
---

## Ports

Snikket currently requires the following ports to be open/forwarded:


 
  
 |**TCP only**   |                                                                                    |
 | :------------ | :--------------------------------------------------------------------------------- |
 | 80/443        | Web Interface And Group File Sharing Service (HTTP(S))                             |                                                                                                 
 | 5222          | Client App Connections (Client to Server) (XMPP-c2s)                               |               
 | 5269          | Federation With Other Snikket Servers (Server to Server) (XMPP-s2s)                |                                                                                                      
 | 5000          | File Transfer Proxy (proxy65)                                                      |
  
 
 |**TCP and UDP**|                                                                                    |
 | :-------------| :--------------------------------------------------------------------------------- |
 | 3478/3479     | Audio/Video Data Proxy Negotiation and IP discovery <br /> (STUN/TURN)                    |
 | 5349/5350     | Audio/Video Data Proxy Negotiations and IP Discovery over TLS <br /> (STUN/TURN over TLS) |


 |**UDP only**  |                                                                                    |
 | :----------- | :----------------------------------------------------------------------------------|
 | 49152-65535  | Audio/Video Data Proxy (Turn Data, see below)                                      |

Obviously your server may need additional ports open as well as these, depending on what services you run.
For example you will definitely want to keep your SSH port (usually port 22) open if you manage your server
via SSH!

## Changing the turnserver port range

The STUN/TURN server is required for audio/video (A/V) calls to work reliably on all kinds of "difficult" client networks. For this, a relay connection is established which routes the (encrypted) A/V data via your Snikket server. As generally the number of concurrent calls is not known and it needs to compete with ports already in use on the machine, the TURN server defaults to a range with a high number of ports (about 16 thousand). See below for recommendations on picking a smaller number of ports.

However, some appliances will not allow forwarding a large range of UDP ports as normally required for TURN. If you have to forward ports through such an appliance, you can tweak the port range used by the STUN/TURN server using the following two configuration options:

* `SNIKKET_TWEAK_TURNSERVER_MIN_PORT`: Set the lower bound of the port range (default: 49152)
* `SNIKKET_TWEAK_TURNSERVER_MAX_PORT`: Set the upper bound of the port range (default: 65535)

Both numbers must be larger than 1024 and smaller than or equal to 65535. Keeping them above 40000 is generally recommended for network standards reasons. Obviously, the min number must be less than or equal to the max number.

Example for a range of 1024 ports (in your snikket.conf):

```
SNIKKET_TWEAK_TURNSERVER_MIN_PORT=60000
SNIKKET_TWEAK_TURNSERVER_MAX_PORT=61023
```

Make sure to restart the `snikket` container after changing this option and ideally test A/V calls with two phones on different mobile data providers (those are generally most tricky to get working).

### How many ports does the TURN service need?

In general, you can safely assume that a call will never need more than four ports at the same time. That means that with 200 ports, you could in theory initiate up to 50 concurrent calls on your Snikket instance.

However, these ports are a system-wide resource. A port may only be used by a single application at the same time (this is an oversimplification). That means that if your server machine is "rather busy", "many" of the ports in the range you designate for the TURN service may be in use already by other applications. This in turn means that a call may randomly fail to establish based on whether enough ports are available in the range you chose.

Unless you are running an *extremely* busy service on your server, you should be fine if you plan wih 10% headroom. <!-- I checked how many "high ports" (5 digits) were open on the search.jabber.network xmppd at a random point in time, and they were just 800. Given that the high port range has 50k ports and that most users are not going to run a busy service as that, it should be fine. -->

That means that if you have 20 users and want to allow them to start calls at the same time (ignoring *who* they'd call), you should plan for 80 ports, plus 10% head room, gives you about 90 ports.

## Configuring UFW to Allow Ports for Snikket

[UFW](https://wiki.ubuntu.com/UncomplicatedFirewall), the Uncomplicated Firewall, is a user-friendly interface to the more complicated iptables commands that control a Linux systems's firewall. 

It is possible to manually add each of the above ports with `ufw` commands like the following: `# ufw allow 5000/tcp comment 'File Transfer Proxy (proxy65)'`, however, doing so is tedious and clutters the output of `# ufw status`. A better way is to create a custom ufw application, which we will call "Snikket" and have ufw add rules for that application. This is not only easier and declarative but also has the advantage of yielding a clean `# ufw status` report that looks as follows:

```
To       Action    From 
--       ------    ----
Snikket  ALLOW     Anywhere
```

Create the following file at `/etc/ufw/applications.d/ufw-snikket`. I have opted to open UDP ports 6000-6200 in the following example, but you should change this to reflect which TURN ports your Snikket configuration specifies.

```
[Snikket]
title=Snikket Server
description=Simple XMPP Server
ports=80/tcp|443/tcp|5222/tcp|5269/tcp|5000/tcp|3478|3479|5349|5350|6000:6200/udp
```

Add the new rule:
`# ufw allow snikket`

Running `# ufw status` should now show Snikket as a rule. If you want to see all the specific ports that have been allowed by adding this rule you can run `# ufw status verbose`.
