# Debian bookworm-slim docker image with Private Internet Access (PIA) Integration

This is a base Docker image based on Debian bookworm-slim that forwards all requests through Private Internet Access (PIA) via OpenVPN. This image is not meant to be used alone! **Supports both x86 & ARM.**

The image's base configuration includes an iptables killswitch, DNS nameserver overrides, and IPv6 blocking to prevent IP leakage when the tunnel goes down. If OpenVPN fails to reconnect or has a fault, the container will automatically kill itself. All permissions are dropped where possible. A healthcheck script is also included that monitors network connectivity and the health of spawned processes.

# Image Features
* Base: Debian bookworm-slim (**supports x86 & ARM**)
* Automatically connects to Private Internet Access (PIA) using OpenVPN
* IP tables killswitch to prevent IP leaking when VPN connection fails
* DNS overrides to avoid DNS leakage
* Blocks IPv6 to avoid leakage
* Drops all permissions where possible
* Auto checks VPN and application health every 10 seconds, with configurable health checks
* Simplified configuation options
* Automatically calls added /entrypoint.sh without passing VPN or HEALTHCHECK environmental variables

# How to Use

Simply:
- Specify this as your base image (i.e. `FROM ghcr.io/pr0fg/pia-docker-base:latest`)
- Add any build instructions using `RUN`, `ADD`, etc.
- Add an `/entrypoint.sh` file
- Add an `ENV` that specifies the name of the process to monitor using the integrated health check (e.g. `ENV HEALTHCHECK_PROCESS_NAME=squid`). This is not required!
- Expose any other volumes, ports, etc.
- **Do not override `CMD` or `ENTRYPOINT`!**

When running your image, include any mandatory/optional environmental variables to ensure the base image can connect to PIA using OpenVPN (see below).

When the image is run, it will automatically connect to PIA using OpenVPN and will call `/entrypoint.sh` once the tunnel is up and running. No VPN or HEALTHCHECK environmenal variables will be visible to this script.

# Example Docker Image
```
FROM ghcr.io/pr0fg/pia-docker-base:latest

WORKDIR /opt

# ------------------------------------------------------------------------
# INSTALL DEPENDENCIES
# ------------------------------------------------------------------------
RUN apt update \
    && apt install -y --no-install-recommends squid \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# ------------------------------------------------------------------------
# BUILD STEPS
# ------------------------------------------------------------------------
RUN ...

# ------------------------------------------------------------------------
# /entrypoint.sh
# - This is the entrypoint for your application after OpenVPN connects
# - It has no access to VPN or HEALTHCHECK environmentals
# - It is executed automatically and is passed all other environmentals
# ------------------------------------------------------------------------
ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

# ------------------------------------------------------------------------
# HEALTHCHECK_PROCESS_NAME
# - This is the name of the process that is monitored with pgrep (optional)
# - If this process exits, the container will restart
# ------------------------------------------------------------------------
ENV HEALTHCHECK_PROCESS_NAME=squid

# ------------------------------------------------------------------------
# OTHER NOTES
#  - Do not set CMD or ENTRYPOINT, /entrypoint.sh will be called automatically
#  - All VPN and HEALTHCHECK environmental variables are not visible to 
#    /entrypoint.sh or your application
# ------------------------------------------------------------------------
EXPOSE 8080 # If needed

```

# Environment Variables
| Variable | Required | Function | Example | Default |
|----------|----------|----------|---------|---------|
|`VPN_REGION`| Yes | PIA VPN Region | `VPN_REGION=ca_toronto`||
|`VPN_USERNAME`| Yes | PIA username | `VPN_USERNAME=pXXXXXX`||
|`VPN_PASSWORD`| Yes | PIA password | `VPN_PASSWORD=XXXXXXX`||
|`VPN_USE_UDP`| No | Use TCP | `VPN_USE_UDP=1`| false |
|`LAN_NETWORK`| Yes | Local network with CIDR notation | `LAN_NETWORK=192.168.1.0/24`||
|`HEALTHCHECK_PROCESS_NAME`| No | Process health check process name |`HEALTHCHECK_PROCESS_NAME=squid`|**Note: Add in Dockerfile!**|
|`TZ`| No | Timezone |`TZ=America/Toronto`| System default |
|`NAME_SERVERS`| No | Comma delimited name servers |`NAME_SERVERS=1.1.1.1,1.0.0.1`| 1.1.1.1,8.8.8.8,1.0.0.1,8.8.4.4 |
|`HEALTHCHECK_INTERVAL`| No | Seconds between health checks |`HEALTHCHECK_INTERVAL=30`| 10 seconds |
|`HEALTHCHECK_DNS_HOST`| No | DNS health check host |`HEALTHCHECK_DNS_HOST=abc.com`| google.com |
|`HEALTHCHECK_PING_IP`| No | Ping health check IP |`HEALTHCHECK_PING_IP=1.2.3.4`| 8.8.8.8 |

`LAN_NETWORK` is required to ensure packets can return to their source.

# How to setup PIA VPN
The container will fail to boot if any of the config options are not set or if `VPN_REGION` does not map to a valid .ovpn file present in the /etc/openvpn/configs directory. If no `VPN_REGION` is set, the container will display all available regions. Simply set `VPN_REGION` to the PIA region you prefer (e.g. `VPN_REGION=ca_toronto`) with no .ovpn extension. Auto injects credentials from `VPN_USERNAME` and `VPN_PASSWORD` into a temporary .ovpn file.

# Issues
If you are having issues with this container please submit an issue on GitHub.  
Please provide logs, Docker version and other information that can simplify reproducing the issue.  
If possible, always use the most up to date version of Docker, you operating system, kernel and the container itself. Support is always a best-effort basis.

### Credits:
[DyonR/docker-qbittorrentvpn](https://github.com/DyonR/docker-qbittorrentvpn)
[MarkusMcNugen/docker-qBittorrentvpn](https://github.com/MarkusMcNugen/docker-qBittorrentvpn)  
[DyonR/jackettvpn](https://github.com/DyonR/jackettvpn)  
