#!/usr/bin/env bash
# Enable IPv4 and IPv6 forwarding on the host for Tailscale exit node / subnet routes.
# See: https://tailscale.com/kb/1104/enable-ip-forwarding/
# Run on the host (not inside a container). Usage: sudo ./scripts/enable-ip-forwarding.sh

set -e

CONF="/etc/sysctl.d/99-tailscale.conf"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (e.g. sudo $0)" >&2
  exit 1
fi

mkdir -p "$(dirname "$CONF")"

# Add only if not already present
for key in "net.ipv4.ip_forward" "net.ipv6.conf.all.forwarding"; do
  if ! grep -q "^${key}" "$CONF" 2>/dev/null; then
    echo "${key} = 1" >> "$CONF"
    echo "Added: ${key} = 1"
  fi
done

# Apply
sysctl -p "$CONF"

echo "IP forwarding enabled. Restart Tailscale container if it was already running: docker compose restart tailscale"
