FROM ubuntu:22.04

ENV WARP_VERSION="2023.10.120-1"
ENV WARP_DEB_URL="https://pkg.cloudflareclient.com/pool/jammy/main/c/cloudflare-warp/cloudflare-warp_2023.10.120-1_amd64.deb"
ENV WARP_DEB_SHA256="bcdcf3e541f992600fff5e2151190f1ed9285414c7d37e807efa037663803ef0"

COPY entry.sh /entry.sh

RUN apt update \
  && apt install -y \
  ca-certificates curl \
  iproute2 \
  # wrap dependencies
  systemctl libdbus-1-3 libc6 iproute2 nftables gnupg2 desktop-file-utils libcap2-bin libnss3-tools \
  && cd /tmp \
  && curl $WARP_DEB_URL -o warp.deb \
  && echo "$WARP_DEB_SHA256  warp.deb" | sha256sum -c - \
  && dpkg -i warp.deb \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

VOLUME /var/lib/cloudflare-warp

ENTRYPOINT ["/bin/bash", "/entry.sh"]
