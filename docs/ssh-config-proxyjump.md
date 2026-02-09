# SSH Config & ProxyJump: Multi-Hop Remote Access

> When you can't reach a machine directly, use another machine as a jump host. SSH's `ProxyJump` makes this seamless -- one command, automatic hop.

---

## The Problem

You have two machines at home:
- **Mac Studio** -- has Tailscale, reachable from anywhere
- **Mac Mini** -- no Tailscale, only reachable on the local network

From outside your home, you can't reach the Mac Mini directly. But you *can* reach the Mac Studio, which *can* reach the Mac Mini.

```
You (hotel/cafe)  ──X──>  Mac Mini (no Tailscale)
You (hotel/cafe)  ────>   Mac Studio (Tailscale)  ────>  Mac Mini (LAN)
```

---

## Manual Two-Step SSH

Without configuration, you'd do this:

```bash
# Step 1: SSH into the jump host
ssh user@mac-studio

# Step 2: From the jump host, SSH into the target
ssh user@mac-mini.local
```

This works, but it's tedious. Every file transfer requires two hops manually. And you can't use tools like `scp` or VS Code Remote directly.

---

## ProxyJump: One Command, Automatic Hop

### SSH Config Setup

Edit `~/.ssh/config`:

```ssh-config
# Jump host -- reachable via Tailscale from anywhere
Host mac-studio
    HostName mac-studio          # Tailscale hostname
    User youruser

# Target machine -- reachable only via jump host
Host mac-mini
    HostName my-mac-mini.local    # Bonjour/mDNS hostname
    User youruser
    ProxyJump mac-studio               # Automatically hop through mac-studio
```

Now:

```bash
ssh mac-mini    # One command -- SSH handles the hop automatically
```

Behind the scenes, SSH connects to `mac-studio` first, then tunnels through to `mac-mini`. You don't see the intermediate step.

### File Transfer Also Works

```bash
# Copy a file to mac-mini (automatically goes through mac-studio)
scp myfile.txt mac-mini:~/

# Or use rsync
rsync -avz ./project/ mac-mini:~/project/
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
# Example output: my-mac-mini
# So the .local address is: my-mac-mini.local
```

This means you don't need to remember IP addresses on your local network:

```bash
ssh user@my-mac-mini.local    # Works if both machines are on the same LAN
```

### Keep a Record of Both

`.local` hostnames are convenient but can occasionally fail (mDNS cache, network issues). Always keep the IP as a backup:

| Machine | .local Hostname | IP Address | Tailscale IP |
|---------|----------------|------------|-------------|
| Mac Studio | mac-studio.local | 192.168.1.x | 100.x.x.x |
| Mac Mini | my-mac-mini.local | 192.168.1.x | -- |

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
ssh-copy-id mac-studio
ssh-copy-id mac-mini    # Run this while on the same LAN, or after ProxyJump is configured
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
Host mac-mini
    HostName my-mac-mini.local
    User youruser
    ProxyJump mac-studio
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
Host mac-studio
    HostName mac-studio
    User youruser

# Access via jump host
Host mac-mini
    HostName your-mac-mini.local
    User youruser
    ProxyJump mac-studio

# Alternative: access mac-mini by IP (fallback if .local fails)
Host mac-mini-ip
    HostName 192.168.1.x
    User youruser
    ProxyJump mac-studio
```

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| `.local` hostname not resolving | Use IP address instead; check that both machines are on the same network |
| `ProxyJump` not working | Verify the jump host is reachable first: `ssh mac-studio` |
| Permission denied on jump | Check that your SSH key is on both the jump host AND the target |
| Connection timeout through jump | The target machine may have SSH disabled; check `Remote Login` in System Settings |
| "Host key verification failed" | The target's IP changed; run `ssh-keygen -R <hostname>` to clear old key |

---

*ProxyJump turns a "can't reach it" into "one command." Set it up once, and every future emergency is just `ssh mac-mini` away.*
