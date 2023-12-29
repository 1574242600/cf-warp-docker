FROM ubuntu:20.04

ENV WARP_VERSION="2022.7.472-1"
ENV WARP_DEB_URL="https://pkg.cloudflareclient.com/pool/dists/focal/main/cloudflare_warp_2022_7_472_1_amd64_77aa79eba3_amd64.deb"
ENV WARP_DEB_SHA256="95b4f7b87d2451b1694af11871f761e639e968a20dc17a2d0f789e3f05c702c6"

COPY entry.sh /entry.sh

RUN apt-get update \
  && apt-get install -y \
  ca-certificates curl \
  iproute2 \
  # wrap dependencies
  systemctl libdbus-1-3 libc6 nftables gnupg2 desktop-file-utils \
  && cd /tmp \
  && curl $WARP_DEB_URL -o warp.deb \
  && echo "$WARP_DEB_SHA256  warp.deb" | sha256sum -c - \
  && dpkg -i warp.deb \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

VOLUME /var/lib/cloudflare-warp

ENTRYPOINT ["/bin/bash", "/entry.sh"]