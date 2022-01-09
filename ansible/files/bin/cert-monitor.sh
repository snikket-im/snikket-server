#!/bin/sh -e

CERT_PATH="/snikket/letsencrypt/live/$SNIKKET_DOMAIN/cert.pem"

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
