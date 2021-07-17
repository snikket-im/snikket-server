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


 |**UDP only**   |                                                                                    |
 | :------------ | :----------------------------------------------------------------------------------|
 | 49152-65535   | Audio/Video Data Proxy (Turn Data)                                                 |
