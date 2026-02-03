#!/usr/bin/env bash
# Fix exit node when "connected but websites don't load".
# - Sets UFW DEFAULT_FORWARD_POLICY=ACCEPT so forwarded traffic is allowed.
# - Restarts Tailscale so iptables rule order is correct with Docker.
# Run on the HOST: sudo ./scripts/fix-exit-node-ufw.sh

set -e

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (e.g. sudo $0)" >&2
  exit 1
fi

UFW_DEFAULT="/etc/default/ufw"
if [[ -f "$UFW_DEFAULT" ]]; then
  if grep -q '^DEFAULT_FORWARD_POLICY="DROP"' "$UFW_DEFAULT"; then
    sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' "$UFW_DEFAULT"
    echo "Set DEFAULT_FORWARD_POLICY=ACCEPT in $UFW_DEFAULT"
    if command -v ufw >/dev/null 2>&1; then
      ufw reload
      echo "Reloaded UFW."
    fi
  else
    echo "UFW forward policy already ACCEPT or not DROP. No change."
  fi
else
  echo "No $UFW_DEFAULT found; skipping UFW."
fi

# Find docker-compose / compose and project dir (same dir as this script's project)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

if command -v docker >/dev/null 2>&1; then
  echo "Restarting Tailscale container (for iptables order)..."
  docker compose restart tailscale 2>/dev/null || docker-compose restart tailscale 2>/dev/null || true
  echo "Done. Wait ~30s then try opening a site from a device using this exit node."
else
  echo "Docker not found; skipped container restart. Run: docker compose restart tailscale"
fi
