# Snikket Combined (Single-Container Prototype)

This is an optional all-in-one build for evaluation. It does not replace the
four-container build or change which images are published to the dev channel.
It uses Debian 13, the shared server Ansible configuration and s6 services,
and a separate Python virtual environment for the unprivileged portal.

## New installation

Run from `snikket-server/`, with Docker and Git available:

```sh
cp snikket.conf.example snikket.conf
# Edit snikket.conf for your domain and email address.
./combined/scripts/fetch-upstreams.sh
docker build -f combined/Dockerfile.combined -t snikket/snikket-allinone:dev .
docker compose -f combined/docker-compose.combined.yml up -d
```

The container is named `snikket`, retaining compatibility with existing operator
scripts. Do not run it alongside the old stack: they use the same host ports.

Component revisions are pinned in `combined/upstreams.lock`, copied into the
image at `/usr/local/share/snikket/combined-upstreams.lock`. To update a component,
change its full commit hash, rerun the fetch script, rebuild and test. The script
checks out detached revisions and refuses dirty existing checkouts. `--no-pull`
uses only revisions already present locally. Python dependency versions still
follow the pinned portal's requirements; they are not fully locked transitively.

## Existing four-container installation

The following assumes the standard named `/snikket` volume. For a custom bind
mount, supply an equivalent mount override instead. Preserve your original
Compose file, configuration and image versions for rollback.

Before stopping the old stack, find its volume and take a backup using your
usual backup procedure:

```sh
export SNIKKET_DATA_VOLUME=$(docker inspect snikket --format '{{range .Mounts}}{{if eq .Destination "/snikket"}}{{.Name}}{{end}}{{end}}')
test -n "$SNIKKET_DATA_VOLUME"
docker volume inspect "$SNIKKET_DATA_VOLUME"
```

Build the combined image as above. Stop the old stack with its original Compose
file and project options (`docker compose ... down`, **without `-v`**). Then run:

```sh
docker compose -f combined/docker-compose.combined.yml \
  -f combined/docker-compose.migrate.yml up -d
```

The migration override requires `SNIKKET_DATA_VOLUME` and uses that existing
volume; it cannot silently create an empty replacement. Keep using both files
and the same variable for later Compose operations. Without the override, the
file under `combined/` derives a different default project/volume name from the
old root Compose file.

Verify login, users, messages, uploads and certificates before retiring the old
configuration. Existing backup/restore helpers still find container `snikket`.
To roll back, stop the combined stack without deleting volumes and start the
original stack. Restore the pre-upgrade backup if reverting a storage-format
change; do not run old and new containers simultaneously against the same data.

## External gateway / certificate management

- `SNIKKET_TWEAK_WEB_PROXY=1` (default): run nginx and cert-monitor.
- `SNIKKET_TWEAK_WEB_PROXY=0`: disable both.
- `SNIKKET_TWEAK_CERT_MANAGER=1` (default): issue certificates via certbot/anacron.
- `SNIKKET_TWEAK_CERT_MANAGER=0`: disable issuance, retaining certificate import.

Disabling the built-in proxy requires disabling its certificate manager too.
An external reverse proxy must provide the routes in the bundled nginx templates,
including portal traffic to
`SNIKKET_TWEAK_PORTAL_INTERNAL_HTTP_INTERFACE:SNIKKET_TWEAK_PORTAL_INTERNAL_HTTP_PORT`
and Prosody endpoints to
`SNIKKET_TWEAK_INTERNAL_HTTP_INTERFACE:SNIKKET_TWEAK_INTERNAL_HTTP_PORT`.
These interfaces default to loopback; configure them for your gateway's network.

External certificates belong under `/snikket/letsencrypt/live/<domain>/` for
Prosody import. Built-in ACME challenges use `/var/www/html/.well-known/acme-challenge`.

## Tests

```sh
docker build -f combined/Dockerfile.combined -t snikket-combined:test .
./combined/tests/smoke.sh
./combined/tests/acme.sh
```

Override the image with `SNIKKET_TEST_IMAGE`. Tests create and remove disposable
containers, networks and volumes, without publishing host ports or contacting
Let's Encrypt. The smoke test covers real portal login/profile uploads with
CSRF, localization, an admin-bearing restart, files/SQLite round trips, portal
permissions and external-gateway mode. The ACME test uses a pinned Pebble test CA
with real HTTP-01 validation, forced renewal, certificate import and nginx reload.
GitHub Actions runs both on amd64. This does not cover ARM, federation, TURN media
or a representative production-data upgrade.
