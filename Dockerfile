FROM ubuntu:20.04

ENV WARP_VERSION="2022.2.29-1"
ENV WARP_DEB_URL="https://pkg.cloudflareclient.com/pool/dists/focal/main/cloudflare_warp_2022_2_29_1_amd64_4c914fa5af_amd64.deb"
ENV WARP_DEB_SHA256="d690f6345ce378cce25991144ab471ac3276aa11ffe64ec1fb25de1c94a2bf97"

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