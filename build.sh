#!/bin/sh
# Entrypoint for the crankboy build container.
# Expects the crankboy-app repo mounted at /work with the toolchain
# submodule checked out at /work/toolchain.
#
# Extracted toolchains are cached in /opt/cache (a mounted volume) so
# repeated builds skip re-extraction.
set -e

WORK=/work
CACHE=/opt/cache
TOOLCHAIN_SRC="$WORK/toolchain/linux"

mkdir -p "$CACHE/gcc" "$CACHE/sdk"

GCC_TARBALL=$(ls "$TOOLCHAIN_SRC"/gcc-arm-none-eabi-*.tar.bz2 2> /dev/null | head -n 1)
SDK_TARBALL=$(ls "$TOOLCHAIN_SRC"/PlaydateSDK-*.tar.gz 2> /dev/null | head -n 1)

if [ -z "$GCC_TARBALL" ] || [ -z "$SDK_TARBALL" ]; then
  echo "ERROR: toolchain tarballs not found in $TOOLCHAIN_SRC" >&2
  echo "Run: git submodule update --init toolchain" >&2
  exit 1
fi

# Cache key: names + mtimes of the tarballs. If they changed (submodule
# bumped), re-extract.
STAMP="$CACHE/.extracted"
KEY=$(stat -c '%n:%Y' "$GCC_TARBALL" "$SDK_TARBALL")

if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$KEY" ]; then
  echo "==> toolchain cache hit, skipping extraction"
else
  echo "==> extracting toolchain (one-time, cached afterwards)"
  rm -rf "$CACHE/gcc" "$CACHE/sdk"
  mkdir -p "$CACHE/gcc" "$CACHE/sdk"
  tar -xjf "$GCC_TARBALL" -C "$CACHE/gcc" --strip-components=1
  tar -xzf "$SDK_TARBALL" -C "$CACHE/sdk" --strip-components=1
  printf '%s\n' "$KEY" > "$STAMP"
fi

export PATH="$CACHE/gcc/bin:$PATH"
export PLAYDATE_SDK_PATH="$CACHE/sdk"

echo "==> arm-none-eabi-gcc: $(arm-none-eabi-gcc --version | head -n 1)"
echo "==> building device target"

cd "$WORK"

exec make "$@" PYTHON=python3
