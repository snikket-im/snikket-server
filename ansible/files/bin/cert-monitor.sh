#!/bin/bash

CERT_PATH="/snikket/letsencrypt/live/$SNIKKET_DOMAIN"

if test -d "$CERT_PATH"; then
	prosodyctl --root cert import /snikket/letsencrypt/live
	if test -f "/etc/prosody/certs/$SNIKKET_DOMAIN.crt"; then
		exit 0;
	fi
fi

while sleep 10; do
	if test -d "$CERT_PATH"; then
		prosodyctl --root cert import /snikket/letsencrypt/live
		if test -f "/etc/prosody/certs/$SNIKKET_DOMAIN.crt"; then
			exit 0;
		fi
	fi
done
