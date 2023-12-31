#!/bin/bash
# Modified from https://github.com/DyonR/docker-qbittorrentvpn

set -e

if ! [ -f /entrypoint.sh ]; then
    echo "[ERROR] No entrypoint detected! Your image must add /entrypoint.sh in order to use this base container." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

echo "[INFO] Starting..." | ts '%Y-%m-%d %H:%M:%.S'

check_network=$(ifconfig | grep docker0 || true)
if [[ ! -z "${check_network}" ]]; then
    echo "[ERROR] Network type detected as 'Host', this will cause major issues! Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

set -e

if [[ -z "${VPN_REGION}" ]]; then
    echo "[ERROR] VPN_REGION not specified. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
    echo "[ERROR] The following PIA regions are available:" | ts '%Y-%m-%d %H:%M:%.S'
    ls /etc/openvpn/configs/ | grep ovpn | sed 's/.ovpn//g' | tr '\n', ','
    echo -e "\nExiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

if ! test -f "/etc/openvpn/configs/${VPN_REGION}.ovpn"; then
    echo "[ERROR] VPN_REGION not found in /etc/openvpn/configs." | ts '%Y-%m-%d %H:%M:%.S'
    echo "[ERROR] The following PIA regions are available:" | ts '%Y-%m-%d %H:%M:%.S'
    ls /etc/openvpn/configs/ | grep ovpn | sed 's/.ovpn//g' | tr '\n', ','
    echo -e "\nExiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

echo "[INFO] OpenVPN config file found at /etc/openvpn/configs/${VPN_REGION}" | ts '%Y-%m-%d %H:%M:%.S'
cp "/etc/openvpn/configs/${VPN_REGION}.ovpn" /etc/openvpn/config.ovpn
export VPN_CONFIG="/etc/openvpn/config.ovpn"

sed -i 's/resolv-retry infinite/resolv-retry 15/g' "$VPN_CONFIG"

if [[ -z "$VPN_USE_UDP" ]]; then
    echo "[INFO] Enabling TCP connections for OpenVPN" | ts '%Y-%m-%d %H:%M:%.S'
    sed -i 's/proto udp/proto tcp/g' "$VPN_CONFIG"
    sed -i 's/ 1198$/ 502/g' "$VPN_CONFIG"
fi

if [[ -z "${VPN_USERNAME}" ]]; then
    echo "[ERROR] VPN_USERNAME not specified. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

if [[ -z "${VPN_PASSWORD}" ]]; then
    echo "[ERROR] VPN_PASSWORD not specified. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

echo "${VPN_USERNAME}" > /etc/openvpn/credentials.conf
echo "${VPN_PASSWORD}" >> /etc/openvpn/credentials.conf
echo "auth-user-pass /etc/openvpn/credentials.conf" >> "${VPN_CONFIG}"

export VPN_REMOTE_LINE=$(cat "${VPN_CONFIG}" | grep -P -o -m 1 '(?<=^remote\s)[^\n\r]+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VPN_REMOTE_LINE}" ]]; then
    echo "[INFO] VPN remote line defined as '${VPN_REMOTE_LINE}'" | ts '%Y-%m-%d %H:%M:%.S'
else
    echo "[ERROR] VPN configuration file ${VPN_CONFIG} does not contain 'remote' line. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

export VPN_REMOTE=$(echo "${VPN_REMOTE_LINE}" | grep -P -o -m 1 '^[^\s\r\n]+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VPN_REMOTE}" ]]; then
    echo "[INFO] VPN_REMOTE defined as '${VPN_REMOTE}'" | ts '%Y-%m-%d %H:%M:%.S'
else
    echo "[ERROR] VPN_REMOTE not found in ${VPN_CONFIG}. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

export VPN_PORT=$(echo "${VPN_REMOTE_LINE}" | grep -P -o -m 1 '(?<=\s)\d{2,5}(?=\s)?+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VPN_PORT}" ]]; then
    echo "[INFO] VPN_PORT defined as '${VPN_PORT}'" | ts '%Y-%m-%d %H:%M:%.S'
else
    echo "[ERROR] VPN_PORT not found in ${VPN_CONFIG}. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

export VPN_PROTOCOL=$(cat "${VPN_CONFIG}" | grep -P -o -m 1 '(?<=^proto\s)[^\r\n]+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VPN_PROTOCOL}" ]]; then
    echo "[INFO] VPN_PROTOCOL defined as '${VPN_PROTOCOL}'" | ts '%Y-%m-%d %H:%M:%.S'
else
    export VPN_PROTOCOL=$(echo "${VPN_REMOTE_LINE}" | grep -P -o -m 1 'udp|tcp-client|tcp$' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
    if [[ ! -z "${VPN_PROTOCOL}" ]]; then
        echo "[INFO] VPN_PROTOCOL defined as '${VPN_PROTOCOL}'" | ts '%Y-%m-%d %H:%M:%.S'
    else
        echo "[WARNING] VPN_PROTOCOL not found in ${VPN_CONFIG}, assuming udp" | ts '%Y-%m-%d %H:%M:%.S'
        export VPN_PROTOCOL="udp"
    fi
fi

if [[ "${VPN_PROTOCOL}" == "tcp-client" ]]; then
    export VPN_PROTOCOL="tcp"
fi

export VPN_DEVICE_TYPE=$(cat "${VPN_CONFIG}" | grep -P -o -m 1 '(?<=^dev\s)[^\r\n\d]+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VPN_DEVICE_TYPE}" ]]; then
    export VPN_DEVICE_TYPE="${VPN_DEVICE_TYPE}0"
    echo "[INFO] VPN_DEVICE_TYPE defined as '${VPN_DEVICE_TYPE}'" | ts '%Y-%m-%d %H:%M:%.S'
else
    echo "[ERROR] VPN_DEVICE_TYPE not found in ${VPN_CONFIG}, exiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

export VPN_OPTIONS=$(echo "${VPN_OPTIONS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VPN_OPTIONS}" ]]; then
    echo "[INFO] VPN_OPTIONS defined as '${VPN_OPTIONS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
    echo "[INFO] VPN_OPTIONS not defined (via -e VPN_OPTIONS)" | ts '%Y-%m-%d %H:%M:%.S'
    export VPN_OPTIONS=""
fi

export LAN_NETWORK=$(echo "${LAN_NETWORK}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${LAN_NETWORK}" ]]; then
    echo "[INFO] LAN_NETWORK defined as '${LAN_NETWORK}'" | ts '%Y-%m-%d %H:%M:%.S'
else
    echo "[ERROR] LAN_NETWORK not defined (via -e LAN_NETWORK). Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
    sleep 10
    exit 1
fi

export NAME_SERVERS=$(echo "${NAME_SERVERS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${NAME_SERVERS}" ]]; then
    echo "[INFO] NAME_SERVERS defined as '${NAME_SERVERS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
    echo "[WARNING] NAME_SERVERS not defined (via -e NAME_SERVERS), defaulting to CloudFlare and Google name servers" | ts '%Y-%m-%d %H:%M:%.S'
    export NAME_SERVERS="1.1.1.1,8.8.8.8,1.0.0.1,8.8.4.4"
fi

> /etc/resolv.conf
IFS=',' read -ra name_server_list <<< "${NAME_SERVERS}"
for name_server_item in "${name_server_list[@]}"; do
    name_server_item=$(echo "${name_server_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
    echo "[INFO] Adding ${name_server_item} to resolv.conf" | ts '%Y-%m-%d %H:%M:%.S'
    echo "nameserver ${name_server_item}" >> /etc/resolv.conf
done

# Stash env for OpenVPN --up
declare -px > /tmp/env

echo "[INFO] Starting OpenVPN..." | ts '%Y-%m-%d %H:%M:%.S'
exec openvpn --pull-filter ignore route-ipv6 --pull-filter ignore ifconfig-ipv6 --config "${VPN_CONFIG}" --user nobody --group nogroup --auth-nocache --script-security 2 --up /etc/openvpn/iptables.sh --down /etc/openvpn/stop.sh --persist-tun --persist-key --keepalive 10 60
