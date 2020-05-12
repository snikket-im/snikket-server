#!/bin/sh

CERTFILE="/snikket/letsencrypt/live/$SNIKKET_DOMAIN/fullchain.pem";
KEYFILE="/snikket/letsencrypt/live/$SNIKKET_DOMAIN/privkey.pem";

echo "Waiting for certificates to become available..."
while ! test -f "$CERTFILE" -a -f "$KEYFILE"; do
  sleep 1;
  echo ".";
done

TURN_EXTERNAL_IP="$(snikket-turn-addresses "$SNIKKET_DOMAIN")"


exec /usr/bin/turnserver -c /etc/turnserver.conf --prod \
     --static-auth-secret="$(cat /snikket/prosody/turn-auth-secret)" \
     --cert="$CERTFILE" --pkey "$KEYFILE" -r "$SNIKKET_DOMAIN" \
     -X "$TURN_EXTERNAL_IP"
