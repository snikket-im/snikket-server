#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
image=${SNIKKET_TEST_IMAGE:-snikket-combined:test}
pebble_image=ghcr.io/letsencrypt/pebble@sha256:ddf230642b1a584f519f32e347de1b05a6e4c1f6c35c1863b33effeab5f78199
name=snikket-combined-acme-$(date +%s)-$$
volume=$(docker volume create)
cleanup() {
    result=$?
    if [ "$result" != 0 ]; then
        docker logs "$name" >&2 || true
        docker logs "$name-ca" >&2 || true
    fi
    docker rm -f "$name" "$name-ca" >/dev/null 2>&1 || true
    docker volume rm "$volume" >/dev/null
    docker network rm "$name" >/dev/null 2>&1 || true
    exit "$result"
}
trap cleanup EXIT
docker network create "$name" >/dev/null
docker run -d --name "$name-ca" --network "$name" --network-alias pebble \
    -e PEBBLE_VA_NOSLEEP=1 -e PEBBLE_WFE_NONCEREJECT=0 \
    -v "$PWD/combined/tests/pebble-config.json:/test/review-config.json:ro" \
    "$pebble_image" -config /test/review-config.json >/dev/null
# TLS verification is disabled only for the local, disposable ACME test CA.
options='--server https://pebble:14000/dir --no-verify-ssl'
docker run -d --name "$name" --network "$name" \
    --network-alias example.test --network-alias share.example.test --network-alias groups.example.test \
    --add-host example.test:127.0.0.1 -v "$volume:/snikket" \
    -e SNIKKET_DOMAIN=example.test -e SNIKKET_ADMIN_EMAIL=admin@example.test \
    -e SNIKKET_TWEAK_TURNSERVER=0 -e REPORT_DSN= \
    -e SNIKKET_TWEAK_WEB_PROXY_RELOAD_INTERVAL=1 \
    -e "SNIKKET_CERTBOT_OPTIONS=$options" "$image" >/dev/null
ready=0
for attempt in {1..60}; do
    if docker exec "$name" curl -fkSs https://example.test/login >/dev/null 2>&1 && \
       docker exec "$name" bash -c 'echo >/dev/tcp/127.0.0.1/5222' 2>/dev/null; then
        ready=1
        break
    fi
    sleep 1
done
test "$ready" = 1
cert=/snikket/letsencrypt/live/example.test/fullchain.pem
before=$(docker exec "$name" openssl x509 -in "$cert" -noout -serial)
docker exec "$name" openssl x509 -in "$cert" -noout -ext subjectAltName
# Execute the actual daily jobs in run-parts order, including Prosody import.
docker exec -e "SNIKKET_CERTBOT_OPTIONS=$options --force-renewal" "$name" \
    run-parts --exit-on-error --regex='^(certbot|refresh-certs)$' /etc/cron.daily
after=$(docker exec "$name" openssl x509 -in "$cert" -noout -serial)
test "$before" != "$after"
imported=$(docker exec "$name" openssl x509 -in /etc/prosody/certs/example.test.crt -noout -serial)
test "$imported" = "$after"
for attempt in {1..20}; do
    served=$(docker exec "$name" sh -c 'openssl s_client -connect 127.0.0.1:443 -servername example.test </dev/null 2>/dev/null | openssl x509 -noout -serial')
    if [ "$served" = "$after" ]; then
        echo 'PASS HTTP-01 issuance, renewal, Prosody certificate import and nginx certificate reload'
        exit 0
    fi
    sleep 1
done
echo 'nginx did not serve the renewed certificate' >&2
exit 1
