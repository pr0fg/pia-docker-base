#!/bin/bash

HEALTHCHECK_INTERVAL="$1"
HEALTH_DNS_HOST="$2"
HEALTHCHECK_PROCESS_NAME="$3"
HEALTHCHECK_PING_HOST="$4"

if [[ -z "$1" ]]; then
    HEALTHCHECK_INTERVAL=10
fi

if [[ -z "$2" ]]; then
    HEALTH_DNS_HOST="google.com"
fi

if [[ -z "$4" ]]; then
    HEALTHCHECK_PING_HOST="8.8.8.8"
else
    HEALTHCHECK_PING_HOST=$(echo "$HEALTHCHECK_PING_HOST" | cut -d',' -f1)
fi

echo "[INFO] Healthcheck settings => Interval: $HEALTHCHECK_INTERVAL DNS Host: $HEALTH_DNS_HOST Ping Host: $HEALTHCHECK_PING_HOST Process: $3"

sleep 15

while true; do

    # DNS Check
    if ! nslookup "$HEALTH_DNS_HOST" 2>&1 >/dev/null; then
        echo "[WARNING] DNS resolution failed. Exiting..." | ts '%Y-%m-%d %H:%M:%.S'
        kill 1
    fi

    # Ping Check
    if ! ping -c 2 -w 5 "$HEALTHCHECK_PING_HOST" 2>&1 >/dev/null; then
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
