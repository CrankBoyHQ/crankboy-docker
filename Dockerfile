FROM --platform=$TARGETPLATFORM debian:trixie-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
  make \
  bzip2 \
  xxd \
  gzip \
  python3 \
  python3-pip \
  ca-certificates \
  libpng16-16 \
  zlib1g \
    && pip3 install --break-system-packages --root-user-action=ignore fontTools Pillow \
  && rm -rf /var/lib/apt/lists/*

COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh
ENTRYPOINT ["build.sh"]
