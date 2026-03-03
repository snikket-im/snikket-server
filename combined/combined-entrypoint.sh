#!/bin/bash

set -euo pipefail

if [ -z "${SNIKKET_DOMAIN:-}" ]; then
    echo "Please provide SNIKKET_DOMAIN"
    exit 1
fi

if [ -z "${SNIKKET_ADMIN_EMAIL:-}" ]; then
    echo "Please provide SNIKKET_ADMIN_EMAIL"
    exit 1
fi

WEB_PROXY="${SNIKKET_TWEAK_WEB_PROXY:-1}"
CERT_MANAGER="${SNIKKET_TWEAK_CERT_MANAGER:-1}"

if [ "$WEB_PROXY" != "0" ] && [ "$WEB_PROXY" != "1" ]; then
    echo "SNIKKET_TWEAK_WEB_PROXY must be 0 or 1 (got: $WEB_PROXY)"
    exit 1
fi

if [ "$CERT_MANAGER" != "0" ] && [ "$CERT_MANAGER" != "1" ]; then
    echo "SNIKKET_TWEAK_CERT_MANAGER must be 0 or 1 (got: $CERT_MANAGER)"
    exit 1
fi

if [ "$WEB_PROXY" = "0" ] && [ "$CERT_MANAGER" = "1" ]; then
    echo "Invalid config: SNIKKET_TWEAK_CERT_MANAGER=1 requires SNIKKET_TWEAK_WEB_PROXY=1. Set SNIKKET_TWEAK_CERT_MANAGER=0 when using an external gateway."
    exit 1
fi

export SNIKKET_DOMAIN_ASCII
SNIKKET_DOMAIN_ASCII=$(idn2 "$SNIKKET_DOMAIN")

if [ -z "${SNIKKET_SMTP_URL:-}" ]; then
    SNIKKET_SMTP_URL="smtp://localhost:1025/;no-tls"
fi

echo "$SNIKKET_SMTP_URL" | smtp-url-to-msmtp > /etc/msmtprc
echo "from snikket@$SNIKKET_DOMAIN_ASCII" >> /etc/msmtprc
unset SNIKKET_SMTP_URL

PUID=${PUID:-$(stat -c %u /snikket)}
PGID=${PGID:-$(stat -c %g /snikket)}

if [ "$PUID" != "0" ] && [ "$PGID" != "0" ]; then
    usermod -o -u "$PUID" prosody
    groupmod -o -g "$PGID" prosody
    usermod -o -u "$PUID" letsencrypt
    groupmod -o -g "$PGID" letsencrypt
fi

if ! test -d /snikket/prosody; then
    install -o prosody -g prosody -m 750 -d /snikket/prosody
fi

if ! test -d /snikket/letsencrypt; then
    install -o letsencrypt -g letsencrypt -m 750 -d /snikket/letsencrypt
fi

install -o prosody -g prosody -m 755 -d /var/run/prosody
install -o letsencrypt -g letsencrypt -m 750 -d /var/lib/letsencrypt
install -o letsencrypt -g letsencrypt -m 750 -d /var/log/letsencrypt
install -o letsencrypt -g letsencrypt -m 755 -d /var/www/html/.well-known/acme-challenge
install -o letsencrypt -g letsencrypt -m 755 -d /var/www/.well-known
rm -rf /var/www/.well-known/acme-challenge
ln -s /var/www/html/.well-known/acme-challenge /var/www/.well-known/acme-challenge

chown -R prosody:prosody /var/spool/anacron /var/run/prosody /snikket/prosody /etc/prosody

if ! chown -R letsencrypt:letsencrypt /snikket/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt /var/www/html/.well-known/acme-challenge; then
    echo "WW: Failed to adjust the permissions of some letsencrypt files/directories"
fi

if [ "$CERT_MANAGER" = "0" ]; then
    chmod 0644 /etc/cron.daily/certbot
else
    chmod 0555 /etc/cron.daily/certbot
fi

if ! test -f /snikket/prosody/turn-auth-secret-v2; then
    head -c 32 /dev/urandom | base64 > /snikket/prosody/turn-auth-secret-v2
fi

if ! test -f /snikket/prosody/oauth2-registration-secret; then
    head -c 32 /dev/urandom | base64 > /snikket/prosody/oauth2-registration-secret
fi

# COMPAT w/ alpha.20200513: remove older format
if test -f /snikket/prosody/turn-auth-secret; then
    rm /snikket/prosody/turn-auth-secret
fi

# Migrate between storage backends if needed.
if test "${SNIKKET_TWEAK_STORAGE:-files}" = "sqlite" && ! test -f /snikket/prosody/prosody.sqlite; then
    sed -i "s/SNIKKET_DOMAIN/$SNIKKET_DOMAIN/" /etc/prosody/migrator.cfg.lua
    if prosody-migrator files sqlite; then
        find /snikket/prosody -mindepth 2 -maxdepth 3 -type f \( -name '*.dat' -o -name '*.list' -o -name '*.lidx' \) -delete
        find /snikket/prosody -mindepth 1 -type d -empty -delete
    else
        rm -fv /snikket/prosody/prosody.sqlite
        exit 1
    fi
elif test "${SNIKKET_TWEAK_STORAGE:-files}" = "files" && test -f /snikket/prosody/prosody.sqlite; then
    sed -i "s/SNIKKET_DOMAIN/$SNIKKET_DOMAIN/" /etc/prosody/migrator.cfg.lua
    if prosody-migrator sqlite files; then
        rm -fv /snikket/prosody/prosody.sqlite
    else
        find /snikket/prosody -mindepth 2 -maxdepth 3 -type f \( -name '*.dat' -o -name '*.list' -o -name '*.lidx' \) -delete
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

CERT_PATH="/snikket/letsencrypt/live/$SNIKKET_DOMAIN_ASCII/fullchain.pem"
PROTOS="${SNIKKET_TWEAK_WEB_PROXY_PROTOS:-http https}"

if [ "$WEB_PROXY" = "1" ]; then
    if test -f "$CERT_PATH"; then
        /usr/local/bin/render-template.sh "/etc/nginx/templates/snikket-common" "/etc/nginx/snippets/snikket-common.conf"
        for proto in $PROTOS; do
            /usr/local/bin/render-template.sh "/etc/nginx/templates/$proto" "/etc/nginx/sites-enabled/$proto"
        done
    else
        /usr/local/bin/render-template.sh "/etc/nginx/templates/startup" "/etc/nginx/sites-enabled/startup"
    fi

    if [ "${#SNIKKET_DOMAIN_ASCII}" -gt 35 ]; then
        sed 's/server_names_hash_bucket_size .*$/server_names_hash_bucket_size 128;/' /etc/nginx/nginx.conf
    fi
else
    echo "Built-in web proxy disabled by environment."
fi

exec s6-svscan /etc/sv
