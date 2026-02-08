# Remote SSH to Mac via Cloudflare Tunnel (Browser-Based)

Access your Mac from anywhere using just a web browser — no VPN, no port forwarding, no client software needed.

## Prerequisites

- A Mac with SSH (Remote Login) enabled
- A domain managed by Cloudflare (e.g., `bluehawana.com`)
- A free Cloudflare Zero Trust account

## Step 1: Install cloudflared

```bash
brew install cloudflared
```

## Step 2: Authenticate cloudflared

```bash
cloudflared login
```

This opens a browser to authorize cloudflared with your Cloudflare account. Select your domain.

## Step 3: Create a Tunnel

```bash
cloudflared tunnel create mac-remote
```

This generates a tunnel ID and credentials file in `~/.cloudflared/`.

## Step 4: Configure the Tunnel

Create `~/.cloudflared/config.yml`:

```yaml
tunnel: <YOUR_TUNNEL_ID>
credentials-file: /Users/<YOUR_USERNAME>/.cloudflared/<YOUR_TUNNEL_ID>.json

ingress:
  - hostname: ssh.yourdomain.com
    service: ssh://localhost:22
  - service: http_status:404
```

## Step 5: Add DNS Route

```bash
cloudflared tunnel route dns mac-remote ssh.yourdomain.com
```

This creates a CNAME record pointing `ssh.yourdomain.com` to your tunnel.

## Step 6: Install as a System Service

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

## Step 7: Configure Cloudflare Access (Browser SSH)

This is the key step that enables SSH in a web browser.

### 7a: Enable One-Time PIN Authentication

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com)
2. Navigate to **Settings** > **Authentication** > **Login methods**
3. Ensure **One-time PIN** is enabled

### 7b: Create an Access Application

1. Go to **Access controls** > **Applications**
2. Click **Add an application** > **Self-hosted**
3. Configure:
   - **Application name:** `Mac SSH`
   - **Session Duration:** `1 month` (or your preference)
   - **Add public hostname:**
     - Subdomain: `ssh`
     - Domain: `yourdomain.com`
   - **Browser rendering:** `SSH` (important!)
4. Add a policy:
   - **Policy name:** `Allow me`
   - **Action:** `Allow`
   - **Selector:** `Emails`
   - **Value:** your email address
5. Save the application

## Step 8: Connect from Any Device

1. Open any browser (Safari, Chrome, etc.)
2. Navigate to `https://ssh.yourdomain.com`
3. Enter your email address
4. Check your email for the one-time PIN and enter it
5. A terminal appears in the browser
6. Log in with your Mac username and password

## Verification Commands

Check tunnel status:

```bash
cloudflared tunnel list
cloudflared tunnel info mac-remote
```

Check logs:

```bash
tail -f /Library/Logs/com.cloudflare.cloudflared.err.log
```

Test SSH locally:

```bash
nc -z localhost 22 && echo "SSH is running"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Browser downloads a text file instead of showing terminal | Browser rendering is not set to `SSH` in the Access application |
| Access application doesn't save | Make sure a public hostname is added |
| "Enrollment request is invalid" (WARP) | Configure device enrollment policy in Settings > WARP Client |
| Tunnel not connecting | Check logs: `tail -f /Library/Logs/com.cloudflare.cloudflared.err.log` |
| SSH connection refused | Enable Remote Login in System Settings > General > Sharing |

## Architecture

```
iPhone/Any Device                Cloudflare Edge              Your Mac
    Browser          -->    ssh.yourdomain.com     -->    cloudflared
 (HTTPS request)          (Access auth + browser        (tunnel to
                           SSH rendering)              localhost:22)
```

No ports exposed. No VPN. No client software. Just a browser.
