# IP forwarding for Tailscale (exit node / subnet routes)

When running Tailscale as an **exit node** or **subnet router**, the container logs may show:

```text
Warning: IPv6 forwarding is disabled.
Subnet routes and exit nodes may not work correctly.
See https://tailscale.com/s/ip-forwarding
```

This is a **host** setting: the Linux kernel must allow forwarding so traffic can be routed through the Tailscale node. Enable it on the **server where Docker runs**, not inside the container.

## Quick fix (recommended)

On the host:

```bash
sudo ./scripts/enable-ip-forwarding.sh
```

Then restart the Tailscale stack so it picks up the new state:

```bash
docker compose restart tailscale
```

## Manual setup

If you prefer to set it yourself:

```bash
# Create config (if /etc/sysctl.d exists)
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf

# Apply
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

On systems without `/etc/sysctl.d`, append to `/etc/sysctl.conf` and run `sudo sysctl -p /etc/sysctl.conf`.

## Why it’s needed

- **Exit node:** Traffic from other Tailscale devices is sent to this node and then to the internet. The host must forward IP packets between the Tailscale interface and the default route.
- **IPv6:** Tailscale advertises `::/0` for exit nodes; without IPv6 forwarding, IPv6 exit traffic may fail or be unreliable.

Reference: [Tailscale – Enable IP forwarding](https://tailscale.com/kb/1104/enable-ip-forwarding/).
