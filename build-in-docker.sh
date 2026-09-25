#!/bin/sh
# Generic runner: builds the container image and runs a make target for
# the calling project inside it. Designed for use as a git submodule:
#
#   git submodule add https://github.com/CrankBoyHQ/crankboy-toolchain.git toolchain
#   git submodule add https://github.com/CrankBoyHQ/crankboy-docker.git docker
#   ./docker/build-in-docker.sh [make-target] [extra make args...]
#
# The image is amd64-only (matches the toolchain binaries); device builds
# only (the simulator needs a host build).
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

if ! command -v docker > /dev/null 2>&1; then
  echo "ERROR: docker not found." >&2
  exit 1
fi

# Project root: explicit override > superproject (submodule case) >
# caller's git toplevel > caller's cwd.
PROJECT_DIR="${CRANKBOY_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  SUPERPROJECT=$(git -C "$SCRIPT_DIR" rev-parse --show-superproject-working-tree 2> /dev/null)
  if [ -n "$SUPERPROJECT" ]; then
    PROJECT_DIR="$SUPERPROJECT"
  else
    TOPLEVEL=$(git rev-parse --show-toplevel 2> /dev/null)
    PROJECT_DIR="${TOPLEVEL:-$(pwd)}"
  fi
fi
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

TOOLCHAIN_DIR="${CRANKBOY_TOOLCHAIN_DIR:-$PROJECT_DIR/toolchain/linux}"

if [ ! -f "$TOOLCHAIN_DIR"/gcc-arm-none-eabi-*.tar.bz2 ] \
  || [ ! -f "$TOOLCHAIN_DIR"/PlaydateSDK-*.tar.gz ]; then
  echo "ERROR: toolchain tarballs not found in $TOOLCHAIN_DIR." >&2
  echo "Add the toolchain submodule and initialize it:" >&2
  echo "  git submodule add https://github.com/CrankBoyHQ/crankboy-toolchain.git toolchain" >&2
  echo "  git submodule update --init toolchain" >&2
  exit 1
fi

echo "==> building docker image"
docker buildx build --platform linux/amd64 -t playdate-build --load "$SCRIPT_DIR"

mkdir -p "$PROJECT_DIR/.docker-cache"

TARGET="${1:-device}"
shift 2> /dev/null || true

echo "==> running build container for $PROJECT_DIR"
attempt=0
while :; do
  if docker run --rm --platform linux/amd64 \
    --ulimit core=0 \
    -v "$PROJECT_DIR":/work -w /work \
    -v "$PROJECT_DIR/.docker-cache":/opt/cache \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    playdate-build "$TARGET" "$@"; then
    exit 0
  fi
  status=$?
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 2 ]; then
    echo "ERROR: build failed twice, giving up." >&2
    exit "$status"
  fi
  echo "==> build failed (exit $status); likely emulator flakiness, retrying once" >&2
done
