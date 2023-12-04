#!/bin/bash

echo "[WARNING] Killing container due to OpenVPN disconnect..." | ts '%Y-%m-%d %H:%M:%.S'
/usr/bin/kill 1
