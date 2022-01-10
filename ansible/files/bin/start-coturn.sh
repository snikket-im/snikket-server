#!/bin/sh -e

if [ "$SNIKKET_TWEAK_TURNSERVER" = "0" ]; then
	echo "TURN server disabled by environment, not launching.";
	exit 0;
fi

CERTFILE="/etc/prosody/certs/$SNIKKET_DOMAIN.crt";
KEYFILE="/etc/prosody/certs/$SNIKKET_DOMAIN.key";

echo "Waiting for certificates to become available..."
while ! test -f "$CERTFILE" -a -f "$KEYFILE"; do
  sleep 1;
  echo ".";
done

TURN_EXTERNAL_IP="$(snikket-turn-addresses "$SNIKKET_DOMAIN")"

min_port="${SNIKKET_TWEAK_TURNSERVER_MIN_PORT:-49152}"
max_port="${SNIKKET_TWEAK_TURNSERVER_MAX_PORT:-65535}"

exec /usr/bin/turnserver -c /etc/turnserver.conf --prod \
     --static-auth-secret="$(cat /snikket/prosody/turn-auth-secret-v2)" \
     --cert="$CERTFILE" --pkey "$KEYFILE" -r "$SNIKKET_DOMAIN" \
     --min-port "$min_port" --max-port "$max_port" \
     -X "$TURN_EXTERNAL_IP"
