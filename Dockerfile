FROM --platform=linux/amd64 debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  make \
  bzip2 \
  xxd \
  gzip \
  python3 \
  python3-pip \
  ca-certificates \
  libpng16-16 \
  zlib1g \
  && pip3 install --break-system-packages fontTools Pillow \
  && rm -rf /var/lib/apt/lists/*

COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh
ENTRYPOINT ["build.sh"]
