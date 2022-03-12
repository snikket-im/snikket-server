#!/bin/bash

DOMAIN=${SNIKKET_TWEAK_XMPP_DOMAIN:-SNIKKET_DOMAIN}
CERT_PATH="/snikket/letsencrypt/live/$DOMAIN/cert.pem"

if test -f "$CERT_PATH"; then
	prosodyctl --root cert import /snikket/letsencrypt/live
	exit 0;
fi

while sleep 10; do
	if test -f "$CERT_PATH"; then
		prosodyctl --root cert import /snikket/letsencrypt/live
		exit 0;
	fi
done
