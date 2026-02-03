# IP forwarding for Tailscale (exit node / subnet routes)

When running Tailscale as an **exit node** or **subnet router**, the container logs may show:

```text
Warning: IPv6 forwarding is disabled.
Subnet routes and exit nodes may not work correctly.
See https://tailscale.com/s/ip-forwarding
```

This is a **host** setting: the Linux kernel must allow forwarding so traffic can be routed through the Tailscale node. The [Tailscale Docker parameters](https://tailscale.com/docs/features/containers/docker#parameters) do **not** provide a way to enable this from inside the container—you must enable it on the **server where Docker runs**.

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

---

## Exit node: websites not loading (browserleak.com, etc.)

If you use this node as an **exit node** but sites don’t load (e.g. browserleak.com), traffic is not being forwarded correctly. Do the following **on the host** (the machine running Docker):

### 1. Enable IP forwarding (required)

```bash
cd /path/to/tail-x
sudo ./scripts/enable-ip-forwarding.sh
```

Verify it’s on (run on host):

```bash
sysctl net.ipv4.ip_forward net.ipv6.conf.all.forwarding
```

You want both `= 1`. If they are `= 0`, the script didn’t run on this machine or didn’t have effect (e.g. no sudo, or wrong server).

### 2. Restart Tailscale

```bash
docker compose restart tailscale
```

### 3. UFW: allow forwarding (very common cause)

If the host uses **UFW**, its default forward policy is often **DROP**, so exit-node traffic is blocked even when IP forwarding is on. Fix it:

```bash
# Check current policy (often "DROP")
grep DEFAULT_FORWARD_POLICY /etc/default/ufw

# Allow forwarded traffic (required for exit node)
sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
sudo ufw reload
```

### 4. Restart Tailscale after Docker is up (iptables order)

With Docker, Tailscale’s iptables rules must be in the right order or forwarded traffic can be dropped. Restart Tailscale **after** all containers are running:

```bash
cd ~/tail-x
docker compose up -d
# Then restart Tailscale so its forward rules are applied correctly
docker compose restart tailscale
```

Wait ~30 seconds, then try opening a site again from a device using this exit node.

### 5. Confirm you’re on the right machine

IP forwarding must be set on the **host** that runs `docker compose`. If you run Docker on a remote server (e.g. 5.196.129.144), run the script and `sysctl` check **on that server** via SSH, not on your laptop.

### 6. Quick checklist (connected but sites don’t load)

On the **server** (as root or with sudo):

| Step | Command |
|------|--------|
| Forwarding on | `sysctl net.ipv4.ip_forward net.ipv6.conf.all.forwarding` → both `= 1` |
| UFW forward | `grep DEFAULT_FORWARD_POLICY /etc/default/ufw` → set to `ACCEPT` and `ufw reload` |
| Restart order | `docker compose up -d` then `docker compose restart tailscale` |
| Test from container | `docker compose exec tailscale ping -c 2 8.8.8.8` (optional) |
