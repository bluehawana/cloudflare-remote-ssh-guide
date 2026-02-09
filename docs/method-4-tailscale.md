# Method 4: Tailscale + Termius (Simplest Remote SSH)

> The easiest path to remote SSH. Install Tailscale on both devices, sign in, SSH to the Tailscale IP. Done in 5 minutes.

---

## How It Works

```
+------------------+        +-------------------+        +------------------+
|   iPhone         | WireGd |  Tailscale DERP   | WireGd |    Your Mac      |
|                  +------->+  Coordination     +------->+                  |
|  Tailscale App   |        |  Server           |        |  Tailscale App   |
|       +          |        |  (or direct P2P)  |        |  100.x.x.x      |
|  Termius App     |        |                   |        |       |          |
|  SSH to          |<-------+                   |<-------+       v          |
|  100.x.x.x      |        |                   |        |  SSH localhost:22 |
+------------------+        +-------------------+        +------------------+
```

## Setup

### On Your Mac

```bash
# Automated setup
bash scripts/03-setup-tailscale.sh

# Or manually:
brew install tailscale
# Open the app, sign in, then get your IP:
tailscale ip
```

### On Your iPhone

1. Install **Tailscale** from the App Store
2. Sign in with the **same account**
3. Both devices appear in your tailnet

![Tailscale Devices](../resources/05-tailscale-devices.jpeg)
*Tailscale device list -- all your devices on one private network, each with a stable `100.x.x.x` IP.*

## Connect with Termius

| Field | Value |
|-------|-------|
| Host | `100.x.x.x` (your Mac's Tailscale IP) |
| Port | `22` |
| Username | your Mac username |
| Password | your Mac login password |

## Result

![Tailscale SSH](../resources/03-tailscale-ssh.jpeg)
*SSH connection from iPhone to Mac Mini via Tailscale. The tab shows the Tailscale IP `100.x.x.x`.*

## Key Points

- Simplest setup of all remote methods
- Uses WireGuard protocol (fast, encrypted)
- Direct P2P connection when possible, falls back through relay servers
- Free for personal use (up to 100 devices)

> **Note:** Tailscale and WARP both use the iOS VPN slot. You can only use one at a time.
