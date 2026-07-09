#!/usr/bin/env bash
#
# build-wsl-rootfs.sh - Build a flat WSL2-importable rootfs tarball from the
# kdocker Docker image.
#
# WSL's `wsl --import` expects a tarball of a filesystem (not a layered OCI
# image). `docker export` of a created container produces exactly that: a flat
# archive of the container filesystem. This script builds (or reuses) the image,
# creates a throwaway container, exports its filesystem, and gzips the result.
#
# Usage:
#   scripts/build-wsl-rootfs.sh [OPTIONS]
#
# Options:
#   -i, --image NAME     Docker image to export (default: kdocker:wsl-build)
#   -o, --output PATH    Output tarball path (default: dist/kdocker-wsl-rootfs.tar.gz)
#   -b, --build          Build the image from the local Dockerfile first
#   -h, --help           Show this help
#
# Environment:
#   DOCKERFILE           Dockerfile to build from (default: Dockerfile)

set -euo pipefail

IMAGE_NAME="kdocker:wsl-build"
OUTPUT="dist/kdocker-wsl-rootfs.tar.gz"
DO_BUILD=0
DOCKERFILE="${DOCKERFILE:-Dockerfile}"

usage() {
    sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -i | --image)
        [[ $# -ge 2 ]] || {
            echo "Missing value for $1" >&2
            usage 1
        }
        IMAGE_NAME="$2"
        shift 2
        ;;
    -o | --output)
        [[ $# -ge 2 ]] || {
            echo "Missing value for $1" >&2
            usage 1
        }
        OUTPUT="$2"
        shift 2
        ;;
    -b | --build)
        DO_BUILD=1
        shift
        ;;
    -h | --help) usage 0 ;;
    *)
        echo "Unknown option: $1" >&2
        usage 1
        ;;
    esac
done

# Resolve repo root (script lives in scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

log() { printf '\033[0;34m[rootfs]\033[0m %s\n' "$1"; }
err() { printf '\033[0;31m[rootfs]\033[0m %s\n' "$1" >&2; }

if ! command -v docker >/dev/null 2>&1; then
    err "docker is required but was not found on PATH."
    exit 1
fi

if [[ $DO_BUILD -eq 1 ]]; then
    log "Building image $IMAGE_NAME from $DOCKERFILE ..."
    docker build -f "$DOCKERFILE" -t "$IMAGE_NAME" .
fi

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    err "Image '$IMAGE_NAME' not found. Pass --build to build it, or --image NAME."
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

CONTAINER_ID=""
cleanup() {
    if [[ -n $CONTAINER_ID ]]; then
        docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

log "Creating throwaway container from $IMAGE_NAME ..."
CONTAINER_ID="$(docker create "$IMAGE_NAME")"

log "Exporting container filesystem and compressing to $OUTPUT ..."
# Stream the export straight into gzip to avoid a large intermediate tar file.
docker export "$CONTAINER_ID" | gzip -9 >"$OUTPUT"

SIZE="$(du -h "$OUTPUT" | cut -f1)"
SHA="$(sha256sum "$OUTPUT" | cut -d' ' -f1)"

log "Done."
log "  Tarball : $OUTPUT ($SIZE)"
log "  SHA256  : $SHA"
