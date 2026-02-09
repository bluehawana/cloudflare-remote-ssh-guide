# SSH Config & ProxyJump: Multi-Hop Remote Access

> **Note for single-machine users:** If you only have one machine to connect to remotely, you don't need ProxyJump. Skip ahead to [Method 4 (Tailscale)](method-4-tailscale.md) or [Method 3 (Cloudflare WARP)](method-3-cloudflare-warp.md) for simpler direct connection options.

> When you can't reach a machine directly, use another machine as a jump host. SSH's `ProxyJump` makes this seamless -- one command, automatic hop.

---

## The Problem

You have two machines:
- **Jump Server** -- Connected to Tailscale, reachable from anywhere
- **Main Server** -- Not connected to Tailscale, only reachable from your local network

From outside your home/office, you can't reach the Main Server directly. But you *can* reach the Jump Server, which *can* reach the Main Server.

```
You (remote)  ──X──>  Main Server (no Tailscale)
You (remote)  ────>   Jump Server (Tailscale)  ────>  Main Server (LAN)
```

**Example setup:**
- Raspberry Pi 4 with Tailscale installed (Jump Server)
- Ubuntu Server in your basement with no VPN capability (Main Server)
- Need to access the Ubuntu Server while traveling

You can extend this concept to chains of any length, but we'll stick to one jump for clarity.

---

## Manual Two-Step SSH

Without configuration, you'd do this:

```bash
# Step 1: SSH into the jump server
ssh user@jump-server-ip-or-hostname

# Step 2: From the jump server, SSH into the target
ssh user@main-server.local-or-ip
```

This works, but it's tedious. Every file transfer requires two hops manually. And you can't use tools like `scp` or VS Code Remote directly.

---

## ProxyJump: One Command, Automatic Hop

### SSH Config Setup

Edit `~/.ssh/config`:

```ssh-config
# Jump host -- connected to Tailscale, reachable from anywhere
Host jump-server
    HostName jump-server              # Tailscale hostname or IP
    User youruser

# Target machine -- NOT on Tailscale, only reachable via jump host
Host main-server
    HostName main-server.local        # Bonjour/mDNS or IP address
    User youruser
    ProxyJump jump-server             # Automatically hop through jump-server
```

Now:

```bash
ssh main-server    # One command -- SSH handles the hop automatically
```

Behind the scenes, SSH connects to `jump-server` first, then tunnels through to `main-server`. You don't see the intermediate step.

### File Transfer Also Works

```bash
# Copy a file to main-server (automatically goes through jump-server)
scp myfile.txt main-server:~/

# Or use rsync
rsync -avz ./project/ main-server:~/project/
```

---

## macOS Bonjour / mDNS (.local Hostnames)

macOS devices on the same network automatically broadcast their hostname via Bonjour (mDNS). The format is:

```
<hostname>.local
```

To find your Mac's hostname:

```bash
scutil --get LocalHostName
# Example output: my-main-server
# So the .local address is: my-main-server.local
```

This means you don't need to remember IP addresses on your local network:

```bash
ssh user@my-main-server.local    # Works if both machines are on the same LAN
```

### Keep a Record of Both

`.local` hostnames are convenient but can occasionally fail (mDNS cache, network issues). Always keep the IP as a backup:

| Machine | .local Hostname | IP Address | Tailscale IP |
|---------|----------------|------------|-------------|
| Jump Server (RPi) | rpi-jump.local | 192.168.1.10 | 100.x.x.x |
| Main Server (Ubuntu) | ubuntu-server.local | 192.168.1.20 | -- |

Find your IP:
- **macOS:** Hold Option + click WiFi icon in menu bar, or `ipconfig getifaddr en0`
- **Linux:** `hostname -I` or `ip addr show`

---

## Advanced SSH Config Patterns

### Multiple Jump Hosts

```ssh-config
# If you have a chain: Internet → Server A → Server B → Target
Host target
    HostName 10.0.0.5
    User admin
    ProxyJump server-a,server-b
```

### SSH Key Authentication (Recommended)

Password-based SSH works but gets old fast, especially through jump hosts. Set up key-based auth:

```bash
# Generate a key (if you don't have one)
ssh-keygen -t ed25519

# Copy your public key to the remote machine
ssh-copy-id jump-server  # Connects directly via Tailscale
ssh-copy-id main-server  # Run this while on the same LAN, or after ProxyJump is configured
```

### Keep-Alive to Prevent Drops

```ssh-config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

This sends a keepalive packet every 60 seconds. If 3 consecutive keepalives fail (3 minutes of no response), SSH disconnects cleanly instead of hanging.

### Compression for Slow Connections

```ssh-config
Host main-server
    HostName your-main-server.local
    User youruser
    ProxyJump jump-server
    Compression yes    # Helpful on slow hotel WiFi
```

---

## Complete Example SSH Config

```ssh-config
# Global settings
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    UseKeychain yes            # macOS keychain integration
    IdentityFile ~/.ssh/id_ed25519

# Direct access via Tailscale
Host jump-server
    HostName jump-server.tailscale.net
    User youruser

# Access via jump host
Host main-server
    HostName your-main-server.local
    User youruser
    ProxyJump jump-server

# Alternative: access main-server by IP (fallback if .local fails)
Host main-server-ip
    HostName 192.168.1.20
    User youruser
    ProxyJump jump-server
```

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| `.local` hostname not resolving | Use IP address instead; check that both machines are on the same network |
| `ProxyJump` not working | Verify the jump server is reachable first: `ssh jump-server` |
| Permission denied on jump | Check that your SSH key is on both the jump server AND the target |
| Connection timeout through jump | The target machine may have SSH disabled; check SSH service status |
| "Host key verification failed" | The target's IP changed; run `ssh-keygen -R <hostname>` to clear old key |

---

*ProxyJump turns a "can't reach it from anywhere" into "just `ssh main-server` from anywhere." Set it up once, and every future emergency is just one command away.*