# Snikket Combined (Single-Container Prototype)

This folder contains an optional all-in-one build/run path for evaluation.
It does not replace the default multi-container setup in `docker-compose.yml`.

## Prerequisites

- Run from `snikket-server/`.
- Configure `snikket.conf` (copy from `snikket.conf.example`).
- Docker available on the test host.

## Quick Start

```bash
./combined/scripts/fetch-upstreams.sh
docker build -f combined/Dockerfile.combined -t snikket/snikket-allinone:dev .
docker compose -f combined/docker-compose.combined.yml up -d
```

## Notes

- Upstream repos are cloned into `combined/src/` and updated with `git pull --ff-only`.
- All services run under one `s6` tree from `combined/sv/`.
- ACME webroot is normalized to `/var/www/html/.well-known/acme-challenge`.
- This is for development/evaluation; behavior may diverge from upstream until validated.

## External Gateway / External Cert Mode

The combined image supports disabling built-in gateway/cert behavior:

- `SNIKKET_TWEAK_WEB_PROXY=1` (default): run built-in nginx + cert-monitor.
- `SNIKKET_TWEAK_WEB_PROXY=0`: disable built-in nginx + cert-monitor.
- `SNIKKET_TWEAK_CERT_MANAGER=1` (default): run built-in certbot via anacron cron jobs.
- `SNIKKET_TWEAK_CERT_MANAGER=0`: disable certbot issuance while keeping cert-import cron.

Invalid combination:

- `SNIKKET_TWEAK_WEB_PROXY=0` with `SNIKKET_TWEAK_CERT_MANAGER=1` is rejected at startup.
  If you use an external gateway, also set `SNIKKET_TWEAK_CERT_MANAGER=0`.

When built-in gateway is disabled, your external reverse proxy must route
requests equivalent to Snikket's bundled nginx config, including:

- Portal traffic to `SNIKKET_TWEAK_PORTAL_INTERNAL_HTTP_INTERFACE:SNIKKET_TWEAK_PORTAL_INTERNAL_HTTP_PORT`
- Prosody HTTP endpoints (`/admin_api`, `/invites_api`, `/invites_bootstrap`,
  `/upload`, `/http-bind`, `/xmpp-websocket`, `/.well-known/host-meta`,
  `/.well-known/host-meta.json`) to
  `SNIKKET_TWEAK_INTERNAL_HTTP_INTERFACE:SNIKKET_TWEAK_INTERNAL_HTTP_PORT`

For external certificate management, sync certs to:

- `/snikket/letsencrypt/live/<domain>/`

Prosody import flow depends on this path.

## Useful Commands

```bash
docker compose -f combined/docker-compose.combined.yml logs -f
docker compose -f combined/docker-compose.combined.yml down
```
