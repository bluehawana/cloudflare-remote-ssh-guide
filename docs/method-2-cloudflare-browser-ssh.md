# Method 2: Cloudflare Browser SSH (Zero App, Any Network)

> Access your Mac's terminal from any browser in the world. No apps to install, no VPN to configure.

---

## How It Works

```
+------------------+        +-------------------+        +------------------+
|   Any Device     |  HTTPS |  Cloudflare Edge  |  QUIC  |    Your Mac      |
|                  +------->+                   +------->+                  |
|  Safari/Chrome   |        |  Zero Trust Auth  |        |  cloudflared     |
|  on iPhone/iPad  |        |  OTP via Email    |        |  (tunnel daemon) |
|  or any browser  |        |  Browser SSH      |        |       |          |
|                  |<-------+  Terminal Render   |<-------+       v          |
|  Terminal in     |  HTTPS |                   |  QUIC  |  SSH localhost:22 |
|  browser         |        |                   |        |                  |
+------------------+        +-------------------+        +------------------+
```

## Prerequisites

- A domain managed by Cloudflare (free plan works)
- A free [Cloudflare Zero Trust](https://one.dash.cloudflare.com) account
- SSH enabled on your Mac

## Setup

### On Your Mac: Install Cloudflare Tunnel

```bash
# Automated setup
bash scripts/02-setup-cloudflared.sh

# Or manually:
brew install cloudflared
cloudflared login
cloudflared tunnel create mac-remote
```

### Create `~/.cloudflared/config.yml`

```yaml
tunnel: <YOUR_TUNNEL_ID>
credentials-file: /Users/<USERNAME>/.cloudflared/<TUNNEL_ID>.json

warp-routing:
  enabled: true

ingress:
  - hostname: ssh.yourdomain.com
    service: ssh://localhost:22
  - service: http_status:404
```

### Add DNS route and start the tunnel

```bash
cloudflared tunnel route dns mac-remote ssh.yourdomain.com
sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
```

### Configure Zero Trust Dashboard

```bash
# Interactive walkthrough
bash scripts/02b-configure-zero-trust.sh
```

Or manually in [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com):

1. **Settings > Authentication**: Enable **One-time PIN**
2. **Access > Applications > Add Self-hosted app**:
   - Hostname: `ssh.yourdomain.com`
   - Browser rendering: **SSH** (critical -- not "Disabled"!)
3. **Add Access Policy**:
   - Action: Allow
   - Selector: Emails > your email

## Connect

1. Open any browser on any device
2. Go to `https://ssh.yourdomain.com`
3. Enter your email -> receive OTP -> enter it
4. A terminal appears -> log in with your Mac credentials

## Key Points

- No apps to install on the client side
- Works on any device with a browser
- Protected by Cloudflare Access (email OTP)
- Your Mac makes outbound connections only -- nothing is publicly exposed
