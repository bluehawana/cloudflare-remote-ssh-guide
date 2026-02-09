# Remote SSH to Mac via Cloudflare Tunnel & Tailscale

Four ways to SSH into your Mac from anywhere — from a browser terminal to native SSH clients on your phone.

## Connection Methods Overview

| Method | App | Network | Setup Complexity |
|--------|-----|---------|-----------------|
| Cloudflare Browser SSH | Any browser | Any | Medium |
| Cloudflare WARP + Termius | Termius + 1.1.1.1 | Any (cellular/WiFi) | High |
| Tailscale + Termius | Termius + Tailscale | Any (cellular/WiFi) | Low |
| Direct WiFi | Termius | Home WiFi only | None |

## Prerequisites

- A Mac with SSH (Remote Login) enabled via **System Settings > General > Sharing > Remote Login**
- A domain managed by Cloudflare (e.g., `yourdomain.com`)
- A free Cloudflare Zero Trust account

---

## Part 1: Cloudflare Tunnel Setup (Required for Methods 1 & 2)

### Step 1: Install cloudflared

```bash
brew install cloudflared
```

### Step 2: Authenticate cloudflared

```bash
cloudflared login
```

This opens a browser to authorize cloudflared with your Cloudflare account. Select your domain.

### Step 3: Create a Tunnel

```bash
cloudflared tunnel create mac-remote
```

This generates a tunnel ID and credentials file in `~/.cloudflared/`.

### Step 4: Configure the Tunnel

Create `~/.cloudflared/config.yml`:

```yaml
tunnel: <YOUR_TUNNEL_ID>
credentials-file: /Users/<YOUR_USERNAME>/.cloudflared/<YOUR_TUNNEL_ID>.json

warp-routing:
  enabled: true

ingress:
  - hostname: ssh.yourdomain.com
    service: ssh://localhost:22
  - service: http_status:404
```

> **Important:** `warp-routing: enabled` is required for WARP + Termius (Method 2).

### Step 5: Add DNS Route

```bash
cloudflared tunnel route dns mac-remote ssh.yourdomain.com
```

### Step 6: Add Private Network Route (for WARP + Termius)

```bash
cloudflared tunnel route ip add <YOUR_MAC_IP>/32 mac-remote
```

### Step 7: Install as a System Service

Create `/Library/LaunchDaemons/com.cloudflare.cloudflared.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.cloudflare.cloudflared</string>
    <key>ProgramArguments</key>
    <array>
      <string>/opt/homebrew/bin/cloudflared</string>
      <string>--config</string>
      <string>/Users/YOUR_USERNAME/.cloudflared/config.yml</string>
      <string>tunnel</string>
      <string>run</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Library/Logs/com.cloudflare.cloudflared.out.log</string>
    <key>StandardErrorPath</key>
    <string>/Library/Logs/com.cloudflare.cloudflared.err.log</string>
    <key>KeepAlive</key>
    <dict>
      <key>SuccessfulExit</key>
      <false/>
    </dict>
  </dict>
</plist>
```

Load the service:

```bash
sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
```

---

## Method 1: Cloudflare Browser SSH (No App Needed)

Access your Mac terminal from any browser. No client software required.

### Configure Cloudflare Access

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com)
2. Navigate to **Settings > Authentication > Login methods** and enable **One-time PIN**
3. Go to **Access controls > Applications > Add an application > Self-hosted**
4. Configure:
   - **Application name:** `Mac SSH`
   - **Session Duration:** `1 month`
   - **Public hostname:** subdomain `ssh`, domain `yourdomain.com`
   - **Browser rendering:** `SSH` (critical!)
5. Add a policy:
   - **Policy name:** `Allow me`
   - **Action:** `Allow`
   - **Selector:** `Emails` > your email address
6. Save

### Connect

1. Open any browser on any device
2. Go to `https://ssh.yourdomain.com`
3. Enter your email > receive OTP > enter it
4. A terminal appears > login with your Mac username and password

```
iPhone/Any Device                Cloudflare Edge              Your Mac
    Browser          -->    ssh.yourdomain.com     -->    cloudflared
 (HTTPS request)          (Access auth + browser        (tunnel to
                           SSH rendering)              localhost:22)
```

---

## Method 2: Cloudflare WARP + Termius (Native SSH via Tunnel)

Use Termius (or any SSH client) on your phone over cellular by routing traffic through Cloudflare WARP.

### Zero Trust Dashboard Configuration

#### 1. Enable Gateway Proxy

> **This is the most commonly missed step!**

1. Go to **Traffic policies > Traffic settings**
2. Find **"Allow Secure Web Gateway to proxy traffic"**
3. Turn it **ON**
4. Enable **TCP**, **UDP**, and **ICMP**

Without this, `is_gateway` stays `false` and WARP won't route private network traffic.

#### 2. Configure Split Tunnels

1. Go to **Team & Resources > Devices > Device profiles > Default**
2. Find **Split Tunnels** (set to "Exclude IPs and domains")
3. **Remove** `192.168.0.0/16` from the exclude list
4. Save

This tells WARP to route `192.168.x.x` traffic through the tunnel instead of bypassing it.

#### 3. Configure Device Enrollment

1. Go to **Settings > WARP Client > Device enrollment permissions**
2. Add a rule:
   - **Selector:** `Emails` > your email address
   - **Authentication:** One-time PIN

### iPhone Setup

1. Install **"1.1.1.1: Faster Internet"** from App Store
2. Open the app > Settings > Account > **Login to Cloudflare Zero Trust**
3. Team name: your Zero Trust organization name
4. **Install the VPN profile** when prompted
5. **Important:** Enter Zero Trust mode first, then connect WARP
6. Verify WARP shows as connected

### Connect with Termius

- **Host:** your Mac's local IP (e.g., `192.168.1.216`)
- **Port:** `22`
- **Username:** your Mac username
- **Password:** your Mac login password

### WARP Troubleshooting

| Issue | Solution |
|-------|----------|
| `is_gateway: false` | Enable Gateway proxy in Traffic policies > Traffic settings |
| Config not syncing to iOS | Log out of Zero Trust, delete app, reinstall, re-enroll |
| "Could not establish connection" | Turn off other VPN apps (Tailscale, Shadowrocket, etc.) first |
| Split tunnel not updating | Delete old device registrations in Team & Resources > Devices |
| WARP keeps disconnecting | Enter Zero Trust mode first, then toggle connection on |
| "Enrollment request is invalid" | Check device enrollment policy allows your email |

---

## Method 3: Tailscale + Termius (Simplest for Mobile SSH)

Tailscale creates a private network between your devices with zero configuration.

### Setup

1. **Mac:** Install Tailscale from App Store or `brew install tailscale`
2. **iPhone:** Install Tailscale from App Store
3. Sign in on both devices with the **same account**
4. Note your Mac's Tailscale IP (e.g., `100.x.x.x`)

```bash
# Check your Tailscale IP
tailscale ip
```

### Connect with Termius

- **Host:** your Mac's Tailscale IP (e.g., `100.113.182.107`)
- **Port:** `22`
- **Username:** your Mac username
- **Password:** your Mac login password

> **Note:** Tailscale and WARP both use the iOS VPN slot. You can only use one at a time.

---

## Method 4: Direct WiFi (Home Network Only)

When on the same WiFi network, connect directly.

- **Host:** your Mac's local IP (e.g., `192.168.1.216`)
- **Port:** `22`
- **Username:** your Mac username
- **Password:** your Mac login password

---

## Verification Commands

```bash
# Check tunnel status
cloudflared tunnel list
cloudflared tunnel info mac-remote

# Check private network routes
cloudflared tunnel route ip show

# Check tunnel logs
tail -f /Library/Logs/com.cloudflare.cloudflared.err.log

# Check tunnel metrics (requests, connections)
curl -s http://127.0.0.1:20241/metrics | grep -E "total_requests|concurrent"

# Test SSH locally
nc -z localhost 22 && echo "SSH is running"

# Check Tailscale status
tailscale status
```

## Lessons Learned

- **Gateway proxy must be ON** for WARP private network routing to work
- **`warp-routing: enabled`** must be in the cloudflared config.yml
- **Browser rendering must be set to `SSH`** in the Access application (not "Disabled")
- **Access application needs a public hostname** added or it won't save
- iOS WARP config sync can be unreliable — deleting and reinstalling the app forces a fresh config
- Multiple VPN apps on iOS can conflict — disable others before using WARP
- Tailscale is the simplest path for native SSH clients on mobile
