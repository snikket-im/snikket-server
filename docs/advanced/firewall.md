# Firewall

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


## Changing the turnserver port range

The STUN/TURN server is required for audio/video (A/V) calls to work reliably on all kinds of "difficult" client networks. For this, a relay connection is established which routes the (encrypted) A/V data via your Snikket server. As generally the number of concurrent calls is not known and it needs to compete with ports already in use on the machine, the TURN server defaults to a range with a high number of ports (about 16 thousand).

However, some appliances will not allow forwarding a large range of UDP ports as normally required for TURN. If you have to forward ports through such an appliance, you can tweak the port range used by the STUN/TURN server using the following two configuration options:

* `SNIKKET_TWEAK_TURNSERVER_MIN_PORT`: Set the lower bound of the port range (default: 49152)
* `SNIKKET_TWEAK_TURNSERVER_MAX_PORT`: Set the lower bound of the port range (default: 65535)

Both numbers must be larger than 1024 and smaller than or equal to 65535. Keeping them above 40000 is generally recommended for network standards reasons. Obviously, the min number must be less than or equal to the max number.

Example for a range of 1024 ports (in your snikket.conf):

```
SNIKKET_TWEAK_TURNSERVER_MIN_PORT=60000
SNIKKET_TWEAK_TURNSERVER_MAX_PORT=61023
```

Make sure to restart the `snikket` container after changing this option and ideally test A/V calls with two phones on different mobile data providers (those are generally most tricky to get working).
