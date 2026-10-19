#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: ./combined/scripts/fetch-upstreams.sh [--no-pull]"
    echo "Check out the revisions in combined/upstreams.lock."
    echo "--no-pull requires those revisions to be available in existing clones."
}

FETCH=1
for arg in "$@"; do
    case "$arg" in
        --no-pull) FETCH=0 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; usage >&2; exit 1 ;;
    esac
done

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
COMBINED_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
SRC_DIR="$COMBINED_DIR/src"
mkdir -p "$SRC_DIR"

while read -r name revision; do
    [ -n "$name" ] || continue
    if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
        echo "Expected a full commit hash for $name in upstreams.lock" >&2
        exit 1
    fi
    dest="$SRC_DIR/$name"
    if [ ! -e "$dest/.git" ]; then
        if [ "$FETCH" = 0 ]; then
            echo "Missing clone: $dest (run without --no-pull first)" >&2
            exit 1
        fi
        git clone --no-checkout "https://github.com/snikket-im/$name" "$dest"
    elif [ -n "$(git -C "$dest" status --porcelain)" ]; then
        echo "Refusing to change dirty checkout: $dest" >&2
        exit 1
    fi

    if ! git -C "$dest" cat-file -e "$revision^{commit}" 2>/dev/null; then
        if [ "$FETCH" = 0 ]; then
            echo "Missing commit $revision in $dest" >&2
            exit 1
        fi
        git -C "$dest" fetch origin "$revision"
    fi
    git -C "$dest" checkout --detach "$revision"
done < "$COMBINED_DIR/upstreams.lock"

echo "Pinned upstreams ready in: $SRC_DIR"
