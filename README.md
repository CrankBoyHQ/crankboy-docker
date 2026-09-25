# crankboy-docker

Docker image for building the CrankBoy device build (`CrankBoy.pdx`) on a
local machine using the x86_64 linux toolchain from the
[crankboy-toolchain](https://github.com/CrankBoyHQ/crankboy-toolchain)
submodule.

The image is amd64-only (matches the toolchain binaries). On Apple Silicon
it runs through Rosetta/QEMU.

## Usage (from crankboy-app)

```sh
scripts/docker-build.sh
```

That script builds the image once, mounts the crankboy-app repo at `/work`,
extracts the toolchain tarballs into a cache volume, and runs `make <target>`.
The resulting `CrankBoy.pdx` ends up in the project root, owned by your user.

Supported targets: `device` (default), `all`, `clean`, `fonts`, `db`.
The simulator target is not supported in the container.

## Manual usage

```sh
docker build --platform linux/amd64 -t crankboy-build .
docker run --rm --platform linux/amd64 \
    -v /path/to/crankboy-app:/work -w /work \
    -v crankboy-toolchain-cache:/opt/cache \
    --user "$(id -u):$(id -g)" -e HOME=/tmp \
    crankboy-build device
```

## Requirements

- The `toolchain` submodule in crankboy-app must be checked out
  (`git submodule update --init toolchain`)
- Docker with amd64 emulation support (see below)
- Device builds only; no simulator in the container

## Docker runtimes on Apple Silicon

The image is amd64-only (matches the toolchain binaries), so it always runs
under emulation on Apple Silicon:

- **Colima**: works out of the box via QEMU, no Rosetta needed.
- **Docker Desktop**: enable "Use Rosetta for x86_64/amd64 emulation" in
  settings for decent speed (falls back to QEMU otherwise).
