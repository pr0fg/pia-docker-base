FROM debian:bookworm-slim

WORKDIR /opt

# Install dependencies
RUN apt update \
    && apt install -y --no-install-recommends \
    curl \
    ca-certificates \
    dnsutils \
    inetutils-ping \
    ipcalc \
    iproute2 \
    iptables \
    kmod \
    moreutils \
    net-tools \
    openresolv \
    openvpn \
    procps \
    sudo \
    tzdata \
    unzip \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Setup OpenVPN Configs
RUN rm -rf /etc/openvpn/*
ADD openvpn/ /etc/openvpn/
RUN curl https://www.privateinternetaccess.com/openvpn/openvpn.zip --output /tmp/configs.zip && unzip /tmp/configs.zip -d /etc/openvpn/configs && rm /tmp/configs.zip

# Entrypoint
RUN chmod +x /etc/openvpn/*.sh

ENTRYPOINT ["/bin/bash", "/etc/openvpn/start.sh"]
