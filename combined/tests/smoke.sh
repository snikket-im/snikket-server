#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
image=${SNIKKET_TEST_IMAGE:-snikket-combined:test}
name=snikket-combined-smoke-$(date +%s)-$$
volume=$(docker volume create)
cleanup() {
    result=$?
    if [ "$result" != 0 ]; then docker logs "$name" >&2 || true; fi
    docker rm -f "$name" >/dev/null 2>&1 || true
    docker volume rm "$volume" >/dev/null
    exit "$result"
}
trap cleanup EXIT

docker run --rm --entrypoint bash -v "$volume:/snikket" "$image" -c '
    mkdir -p /snikket/letsencrypt/live/example.test
    openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=example.test \
        -addext "subjectAltName=DNS:example.test,DNS:share.example.test,DNS:groups.example.test" \
        -keyout /snikket/letsencrypt/live/example.test/privkey.pem \
        -out /snikket/letsencrypt/live/example.test/fullchain.pem 2>/dev/null'

ready() {
    local url=${1:-https://example.test/login}
    for attempt in {1..60}; do
        if docker exec "$name" curl -fkSs "$url" >/dev/null 2>&1 && \
           docker exec "$name" bash -c 'echo >/dev/tcp/127.0.0.1/5222' 2>/dev/null; then
            return
        fi
        sleep 1
    done
    echo "Services did not become ready" >&2
    return 1
}
start() {
    docker run -d --name "$name" --add-host example.test:127.0.0.1 \
        -v "$volume:/snikket" -e SNIKKET_DOMAIN=example.test \
        -e SNIKKET_ADMIN_EMAIL=admin@example.test -e SNIKKET_TWEAK_TURNSERVER=0 \
        -e SNIKKET_TWEAK_CERT_MANAGER=0 -e "SNIKKET_TWEAK_STORAGE=$1" \
        -e "SNIKKET_TWEAK_WEB_PROXY=${2:-1}" "$image" >/dev/null
}
portal() {
    docker exec -i -u snikket-portal "$name" /opt/snikket-web-portal/venv/bin/python - "$@" < combined/tests/portal.py
}
start files
ready
docker exec "$name" prosodyctl register review example.test review-test-password
portal
# Verify that the running portal generated its secret as its own user.
docker exec "$name" sh -c 'test "$(stat -c %U /etc/snikket-web-portal/secret_key)" = snikket-portal'
docker exec -u snikket-portal "$name" sh -c 'test ! -r /snikket/letsencrypt/live/example.test/privkey.pem'
# Seed an already-migrated admin role: this used to abort the entrypoint.
docker exec -i "$name" bash <<'INNER'
mkdir -p /snikket/prosody/example%2etest/account_roles
echo 'return { ["_default"] = "prosody:admin"; };' > /snikket/prosody/example%2etest/account_roles/review.dat
chown -R prosody:prosody /snikket/prosody/example%2etest/account_roles
INNER
docker restart "$name" >/dev/null
ready
portal --check
for storage in sqlite files; do
    docker rm -f "$name" >/dev/null
    start "$storage"
    ready
    portal --check
    echo "PASS $storage storage"
done

docker rm -f "$name" >/dev/null
start files 0
ready http://127.0.0.1:5765/login
docker exec "$name" test ! -x /etc/cron.daily/certbot
docker exec "$name" bash -c '! echo >/dev/tcp/127.0.0.1/80' 2>/dev/null
echo 'PASS external gateway/certificate mode and portal isolation'
