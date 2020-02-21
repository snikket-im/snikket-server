#!/bin/sh

if [ -z "$SNIKKET_DOMAIN" ]; then
  echo "Please provide SNIKKET_DOMAIN";
  exit 1;
fi

if [ -z "$SNIKKET_SMTP_URL" ]; then
	SNIKKET_SMTP_URL="smtp://localhost:1025/;no-tls"
fi

echo "$SNIKKET_SMTP_URL" | smtp-url-to-msmtp > /etc/msmtprc

echo "from snikket@$SNIKKET_DOMAIN" >> /etc/msmtprc

unset SNIKKET_SMTP_URL

PUID=${PUID:=$(stat -c %u /snikket)}
PGID=${PGID:=$(stat -c %g /snikket)}

if [ "$PUID" != 0 ] && [ "$PGID" != 0 ]; then
	usermod  -o -u "$PUID" prosody
	groupmod -o -g "$PGID" prosody

	usermod  -o -u "$PUID" letsencrypt
	groupmod -o -g "$PGID" letsencrypt
fi

if ! test -d /snikket/prosody; then
	install -o prosody -g prosody -m 750 -d /snikket/prosody;
fi

chown -R prosody:prosody /var/spool/anacron /var/run/prosody /snikket/prosody /etc/prosody

if ! test -d /snikket/letsencrypt; then
	install -o letsencrypt -g letsencrypt -m 750 -d /snikket/letsencrypt;
fi

install -o letsencrypt -g letsencrypt -m 750 -d /var/lib/letsencrypt;
install -o letsencrypt -g letsencrypt -m 750 -d /var/log/letsencrypt;
install -o letsencrypt -g letsencrypt -m 755 -d /var/www/.well-known/acme-challenge;

chown -R letsencrypt:letsencrypt /snikket/letsencrypt

exec supervisord -c /etc/supervisor/supervisord.conf
