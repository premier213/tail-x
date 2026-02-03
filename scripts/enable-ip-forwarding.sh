#!/usr/bin/env bash
# Enable IPv4 and IPv6 forwarding on the host for Tailscale exit node / subnet routes.
# See: https://tailscale.com/kb/1104/enable-ip-forwarding/
# Run on the HOST (where Docker runs), not inside a container:
#   cd /path/to/tail-x && sudo ./scripts/enable-ip-forwarding.sh

set -e

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (e.g. sudo $0)" >&2
  exit 1
fi

if [[ -d /etc/sysctl.d ]]; then
  CONF="/etc/sysctl.d/99-tailscale.conf"
else
  CONF="/etc/sysctl.conf"
fi

mkdir -p "$(dirname "$CONF")"

# Add only if not already present
for key in "net.ipv4.ip_forward" "net.ipv6.conf.all.forwarding"; do
  if ! grep -q "^[[:space:]]*${key}[[:space:]]*=" "$CONF" 2>/dev/null; then
    echo "${key} = 1" >> "$CONF"
    echo "Added: ${key} = 1"
  fi
done

# Apply
sysctl -p "$CONF" 2>/dev/null || true
# Ensure applied (in case file was already correct)
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

echo ""
echo "Current values:"
sysctl net.ipv4.ip_forward net.ipv6.conf.all.forwarding 2>/dev/null || true
echo ""
echo "Restart Tailscale so it sees the change: docker compose restart tailscale"
