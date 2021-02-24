#!/bin/sh

if [ -z "$SNIKKET_DOMAIN" ]; then
  echo "Please provide SNIKKET_DOMAIN";
  exit 1;
fi

if [ -z "$SNIKKET_ADMIN_EMAIL" ]; then
  echo "Please provide SNIKKET_ADMIN_EMAIL";
  exit 1;
fi

if [ -z "$SNIKKET_SMTP_URL" ]; then
	SNIKKET_SMTP_URL="smtp://localhost:1025/;no-tls"
fi

if [ -z "$SNIKKET_EXTERNAL_IP" ]; then
	SNIKKET_EXTERNAL_IP="$(dig +short $SNIKKET_DOMAIN)"
fi

echo "$SNIKKET_SMTP_URL" | smtp-url-to-msmtp > /etc/msmtprc

echo "from snikket@$SNIKKET_DOMAIN" >> /etc/msmtprc

unset SNIKKET_SMTP_URL

PUID=${PUID:=$(stat -c %u /snikket)}
PGID=${PGID:=$(stat -c %g /snikket)}

if [ "$PUID" != 0 ] && [ "$PGID" != 0 ]; then
	usermod  -o -u "$PUID" prosody
	groupmod -o -g "$PGID" prosody
fi

if ! test -d /snikket/prosody; then
	install -o prosody -g prosody -m 750 -d /snikket/prosody;
fi

chown -R prosody:prosody /var/spool/anacron /var/run/prosody /snikket/prosody /etc/prosody

## Generate secret for coturn auth if necessary
if ! test -f /snikket/prosody/turn-auth-secret-v2; then
	head -c 32 /dev/urandom | base64 > /snikket/prosody/turn-auth-secret-v2;
fi

# COMPAT w/ alpha.20200513: remove older format
if test -f /snikket/prosody/turn-auth-secret; then
	rm /snikket/prosody/turn-auth-secret;
fi

if test -d /snikket/prosody/http_upload; then
	prosodyctl mod_migrate_http_upload "share.$SNIKKET_DOMAIN" "$SNIKKET_DOMAIN"
fi

exec supervisord -c /etc/supervisor/supervisord.conf
