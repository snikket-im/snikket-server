#!/bin/sh

if [ -z "$SNIKKET_DOMAIN" ]; then
  echo "Please provide SNIKKET_DOMAIN";
  exit 1;
fi

export SNIKKET_DOMAIN_ASCII=$(idn2 "$SNIKKET_DOMAIN")

if [ -z "$SNIKKET_ADMIN_EMAIL" ]; then
  echo "Please provide SNIKKET_ADMIN_EMAIL";
  exit 1;
fi

if [ -z "$SNIKKET_SMTP_URL" ]; then
	SNIKKET_SMTP_URL="smtp://localhost:1025/;no-tls"
fi

if [ -z "$SNIKKET_EXTERNAL_IP" ]; then
	SNIKKET_EXTERNAL_IP="$(dig +short $SNIKKET_DOMAIN_ASCII)"
fi

echo "$SNIKKET_SMTP_URL" | smtp-url-to-msmtp > /etc/msmtprc

echo "from snikket@$SNIKKET_DOMAIN_ASCII" >> /etc/msmtprc

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

chown -R prosody:prosody /var/spool/anacron /var/run/prosody /snikket/prosody /etc/prosody /var/log/prosody

## Generate secret for coturn auth if necessary
if ! test -f /snikket/prosody/turn-auth-secret-v2; then
	head -c 32 /dev/urandom | base64 > /snikket/prosody/turn-auth-secret-v2;
fi

# COMPAT w/ alpha.20200513: remove older format
if test -f /snikket/prosody/turn-auth-secret; then
	rm /snikket/prosody/turn-auth-secret;
fi

# Migrate between storage backends if needed
# Note: this happens before we do any other operations that touch Prosody's
# data store, to ensure consistency.

if test "${SNIKKET_TWEAK_STORAGE:-files}" = "sqlite" && ! test -f /snikket/prosody/prosody.sqlite; then
	sed -i "s/SNIKKET_DOMAIN/$SNIKKET_DOMAIN/" /etc/prosody/migrator.cfg.lua
	if prosody-migrator files sqlite; then
		# Migration succeeded, delete leftovers
		find /snikket/prosody -mindepth 2 -maxdepth 3 -type f \( -name \*.dat -o -name \*.list -o -name \*.lidx \) -delete
		find /snikket/prosody -mindepth 1 -type d -empty -delete
	else
		# Migration failed, delete sqlite file and try again
		rm -fv /snikket/prosody/prosody.sqlite
		exit 1
	fi
elif test "${SNIKKET_TWEAK_STORAGE:-files}" = "files" && test -f /snikket/prosody/prosody.sqlite; then
	sed -i "s/SNIKKET_DOMAIN/$SNIKKET_DOMAIN/" /etc/prosody/migrator.cfg.lua
	if prosody-migrator sqlite files; then
		# Migration succeeded, delete leftover database
		rm -fv /snikket/prosody/prosody.sqlite
	else
		# Migration failed, delete files and try again
		find /snikket/prosody -mindepth 2 -maxdepth 3 -type f \( -name \*.dat -o -name \*.list -o -name \*.lidx \) -delete
		find /snikket/prosody -mindepth 1 -type d -empty -delete
		exit 1
	fi
fi

if test -d /snikket/prosody/http_upload; then
	prosodyctl mod_migrate_http_upload "share.$SNIKKET_DOMAIN" "$SNIKKET_DOMAIN"
fi

# COMPAT: migrate from 0.12 series role storage
if ! test -d /snikket/prosody/*/account_roles; then
	prosodyctl mod_authz_internal migrate "$SNIKKET_DOMAIN"
fi

# Migrate from prosody:normal to prosody:registered
prosodyctl mod_migrate_snikket_roles migrate "$SNIKKET_DOMAIN"

exec s6-svscan /etc/sv
