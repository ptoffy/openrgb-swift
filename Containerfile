FROM debian:bookworm-slim

WORKDIR /usr/src

ENV OPENRGB_SERVER_PORT=6742
ENV LOG_LEVEL=debug

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget \
    i2c-tools \
    libusb-1.0-0 \
    libhidapi-dev \
    libmbedtls-dev \
    libqt5gui5 \
    ca-certificates \
    kmod \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/openrgb.deb \
    https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_1.0rc2/openrgb_1.0rc2_amd64_bookworm_0fca93e.deb && \
    dpkg -i /tmp/openrgb.deb || apt-get update && apt-get install -f -y && \
    rm /tmp/openrgb.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN printf '%s\n' \
    "#!/bin/sh" \
    "modprobe i2c-dev 2>/dev/null || true" \
    "modprobe i2c-i801 2>/dev/null || true" \
    "exec /usr/bin/openrgb --server --server-host 0.0.0.0 --server-port \"\${OPENRGB_SERVER_PORT}\" --loglevel \"\${LOG_LEVEL}\"" \
    > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 6742

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
