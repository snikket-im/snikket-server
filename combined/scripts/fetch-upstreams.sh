#!/bin/bash

set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: ./combined/scripts/fetch-upstreams.sh [--no-pull]

Clones missing upstream repos into combined/src/ and optionally fast-forwards
existing clones.
USAGE
}

DO_PULL=1

while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-pull)
            DO_PULL=0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
COMBINED_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
SRC_DIR="$COMBINED_DIR/src"

mkdir -p "$SRC_DIR"

REPOS=(
    "snikket-cert-manager https://github.com/snikket-im/snikket-cert-manager"
    "snikket-web-portal https://github.com/snikket-im/snikket-web-portal"
    "snikket-web-proxy https://github.com/snikket-im/snikket-web-proxy"
)

for repo in "${REPOS[@]}"; do
    name=$(echo "$repo" | awk '{print $1}')
    url=$(echo "$repo" | awk '{print $2}')
    dest="$SRC_DIR/$name"

    if [ ! -d "$dest/.git" ]; then
        echo "Cloning $name..."
        git clone "$url" "$dest"
        continue
    fi

    if [ "$DO_PULL" -eq 1 ]; then
        echo "Updating $name..."
        git -C "$dest" pull --ff-only
    else
        echo "Keeping existing $name clone (no pull)."
    fi
done

echo "Upstreams ready in: $SRC_DIR"
