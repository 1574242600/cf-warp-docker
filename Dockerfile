FROM ubuntu:20.04

ENV WARP_VERSION="2022.4.235-1"
ENV WARP_DEB_URL="https://pkg.cloudflareclient.com/pool/dists/focal/main/cloudflare_warp_2022_4_235_1_amd64_c71a3ae2e7_amd64.deb"
ENV WARP_DEB_SHA256="71b86448b8c03c1a06d61f3f5e54ffce3e2b6831cebe77c571fb9600d30224b7"

COPY entry.sh /entry.sh

RUN apt-get update \
  && apt-get install -y \
  ca-certificates curl \
  iproute2 net-tools \
  # wrap dependencies
  systemctl libdbus-1-3 libc6 nftables gnupg2 \
  && cd /tmp \
  && curl $WARP_DEB_URL -o warp.deb \
  && echo "$WARP_DEB_SHA256  warp.deb" | sha256sum -c - \
  && dpkg -i warp.deb \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

VOLUME /var/lib/cloudflare-warp

ENTRYPOINT ["/bin/bash", "/entry.sh"]
