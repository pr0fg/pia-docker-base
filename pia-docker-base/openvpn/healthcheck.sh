#!/bin/bash

HEALTHCHECK_INTERVAL="$1"
HEALTHCHECK_DNS_HOST="$2"
HEALTHCHECK_PING_IP="$3"
HEALTHCHECK_PROCESS_NAME="$4"

if [[ -z "$HEALTHCHECK_INTERVAL" ]]; then
    HEALTHCHECK_INTERVAL=10
fi

if [[ -z "$HEALTHCHECK_DNS_HOST" ]]; then
    HEALTHCHECK_DNS_HOST="google.com"
fi

if [[ -z "$HEALTHCHECK_PING_IP" ]]; then
    HEALTHCHECK_PING_IP="8.8.8.8"
fi

echo "[INFO] Healthcheck settings => Interval: $HEALTHCHECK_INTERVAL DNS Host: $HEALTHCHECK_DNS_HOST Ping IP: $HEALTHCHECK_PING_IP Process: $HEALTHCHECK_PROCESS_NAME"

sleep 15

while true; do

    # DNS Check
    if ! nslookup "$HEALTHCHECK_DNS_HOST" 2>&1 >/dev/null; then
        echo "[WARNING] DNS resolution failed. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
        kill 1
    fi

    # Ping Check
    if ! ping -c 2 -w 5 "$HEALTHCHECK_PING_IP" 2>&1 >/dev/null; then
        echo "[WARNING] Network is down. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
        kill 1
    fi

    # Entrypoint Process Check
    if [[ ! -z "$HEALTHCHECK_PROCESS_NAME" ]]; then
        if ! pgrep "$HEALTHCHECK_PROCESS_NAME" 2>&1 >/dev/null; then
            echo "[WARNING] $HEALTHCHECK_PROCESS_NAME process not running. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
            kill 1
        fi
    fi

    sleep "$HEALTHCHECK_INTERVAL"

done
