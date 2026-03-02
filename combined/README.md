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

## Useful Commands

```bash
docker compose -f combined/docker-compose.combined.yml logs -f
docker compose -f combined/docker-compose.combined.yml down
```
