# crankboy-docker

Docker image for building Playdate device builds (`*.pdx`) on a local
machine using the x86_64 linux toolchain from the
[crankboy-toolchain](https://github.com/CrankBoyHQ/crankboy-toolchain)
repository. Originally built for CrankBoy, but works for any Playdate
project (see below).

The image is amd64-only (matches the toolchain binaries). On Apple Silicon
it runs through Rosetta/QEMU.

## Usage (from crankboy-app)

```sh
scripts/docker-build.sh
```

That script delegates to `docker/build-in-docker.sh` (with a CrankBoy
target allowlist), which builds the image once, mounts the repo at
`/work`, extracts the toolchain tarballs into a cache volume, and runs
`make <target>`. The resulting `CrankBoy.pdx` ends up in the project
root, owned by your user.

Supported targets: `device` (default), `all`, `clean`, `fonts`, `db`.
The simulator target is not supported in the container.

## Using with other Playdate projects

Add two submodules to your project and call the generic runner:

```sh
git submodule add https://github.com/CrankBoyHQ/crankboy-toolchain.git toolchain
git submodule add https://github.com/CrankBoyHQ/crankboy-docker.git docker
git submodule update --init
./docker/build-in-docker.sh [make-target] [extra make args...]
```

Requirements:

- Your Makefile follows the standard Playdate SDK template (includes
  `C_API/buildsupport/common.mk`, which provides the `device` target)
- The toolchain submodule lives at `toolchain/` (override with
  `CRANKBOY_TOOLCHAIN_DIR`)
- Device builds only; the simulator needs a host build

fontTools and Pillow are preinstalled in the image, so font pipelines
work out of the box. `PYTHON=python3` is passed to make (overridable
per project).

## Manual usage

```sh
docker buildx build --platform linux/amd64 -t playdate-build --load .
docker run --rm --platform linux/amd64 \
    -v /path/to/project:/work -w /work \
    -v /path/to/project/.docker-cache:/opt/cache \
    --user "$(id -u):$(id -g)" -e HOME=/tmp \
    playdate-build device
```

## Requirements

- The `toolchain` submodule must be checked out
  (`git submodule update --init toolchain`)
- Docker with amd64 emulation support (see below)
- Device builds only; no simulator in the container

## Docker runtimes on Apple Silicon

The image is amd64-only (matches the toolchain binaries), so it always runs
under emulation on Apple Silicon:

- **Colima**: works out of the box via QEMU, no Rosetta needed.
- **Docker Desktop**: enable "Use Rosetta for x86_64/amd64 emulation" in
  settings for decent speed (falls back to QEMU otherwise).
