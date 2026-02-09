# Architecture Overview

## Method 1: Cloudflare Browser SSH

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

- No client software needed
- Works on any device with a browser
- Protected by Cloudflare Access (email OTP)
- Terminal rendered by Cloudflare in the browser

## Method 2: Cloudflare WARP + Termius

```
+------------------+        +-------------------+        +------------------+
|   iPhone         |  WARP  |  Cloudflare Edge  |  QUIC  |    Your Mac      |
|                  +------->+                   +------->+                  |
|  1.1.1.1 App     |  VPN   |  Gateway Proxy    |        |  cloudflared     |
|  (Zero Trust)    |  Tunnel|  Split Tunnel      |        |  (warp-routing)  |
|       +          |        |  Route: 192.168.x  |        |       |          |
|  Termius App     |        |  -> tunnel         |        |       v          |
|  SSH to          |<-------+                   |<-------+  SSH localhost:22 |
|  192.168.1.x   |  WARP  |                   |  QUIC  |                  |
+------------------+        +-------------------+        +------------------+
```

- Requires WARP (1.1.1.1) app in Zero Trust mode
- Gateway proxy must be enabled (TCP/UDP/ICMP)
- Split tunnel must exclude 192.168.0.0/16 from bypass list
- Private network route maps Mac IP to tunnel
- Native SSH experience with Termius

## Method 3: Tailscale + Termius

```
+------------------+        +-------------------+        +------------------+
|   iPhone         | WireGd |  Tailscale DERP   | WireGd |    Your Mac      |
|                  +------->+  Coordination     +------->+                  |
|  Tailscale App   |        |  Server           |        |  Tailscale App   |
|       +          |        |  (or direct P2P)  |        |  100.x.x.x |
|  Termius App     |        |                   |        |       |          |
|  SSH to          |<-------+                   |<-------+       v          |
|  100.x.x.x      |        |                   |        |  SSH localhost:22 |
+------------------+        +-------------------+        +------------------+
```

- Simplest setup (install app, sign in, done)
- Uses WireGuard protocol
- Direct P2P connection when possible
- Fallback through Tailscale relay servers
- Cannot run simultaneously with WARP (iOS VPN limitation)

## Method 4: Direct WiFi

```
+------------------+                                     +------------------+
|   iPhone         |          Local Network (WiFi)       |    Your Mac      |
|                  +------------------------------------>+                  |
|  Termius App     |          192.168.1.x/24             |  192.168.1.x   |
|  SSH to          |<------------------------------------+       |          |
|  192.168.1.x   |                                     |       v          |
|                  |                                     |  SSH localhost:22 |
+------------------+                                     +------------------+
```

- Only works on the same network
- No tunnel or VPN needed
- Fastest connection (no overhead)

## Method 5: SSH ProxyJump (Multi-Hop via Jump Host)

```
+------------------+        +-------------------+        +------------------+
|   You            | WireGd |  Mac Studio       |  LAN   |    Mac Mini      |
|   (anywhere)     +------->+  (Jump Host)      +------->+    (Target)      |
|                  |        |                   |        |                  |
|  Termius /       |Tailscl |  Tailscale        | mDNS   |  No Tailscale    |
|  Terminal        |  VPN   |  100.x.x.x       | .local |  192.168.1.x     |
|                  |        |       |           |        |       |          |
|  ssh mac-mini    |<-------+       v           |<-------+       v          |
|  (one command)   |        |  ProxyJump auto   |        |  SSH localhost:22 |
+------------------+        +-------------------+        +------------------+
```

- Uses SSH `ProxyJump` for seamless multi-hop
- Jump host must have Tailscale (or other external access)
- Target machine only needs SSH enabled + LAN connectivity
- One command: `ssh mac-mini` (SSH handles the hop)
- Works even if the target has no VPN/tunnel installed
- macOS Bonjour (`.local`) eliminates need to remember IPs

## Method 6: Mobile + AI Remote Workflow

```
+------------------+        +-------------------+        +------------------+
|   Phone          |  SSH   |  Remote Machine   |  AI    |    Service       |
|                  +------->+                   +------->+                  |
|  Typeless        | via    |  Claude Code      | cmds   |  FastAPI /       |
|  (voice input)   | Termius|  (AI agent)       |        |  any service     |
|       |          |        |       |           |        |       |          |
|       v          |        |       v           |        |       v          |
|  "fix the api"   |        |  check logs       |        |  service restart |
|                  |        |  find error        |        |  verified OK     |
|                  |<-------+  restart service  |<-------+                  |
+------------------+        +-------------------+        +------------------+
```

- Voice input (Typeless) → text command to Claude Code
- Claude Code autonomously debugs and fixes issues
- No typing on tiny phone keyboards
- Full workflow: alert → SSH → AI → fixed → back to sleep

## Comparison

| Feature | Browser SSH | WARP+Termius | Tailscale | ProxyJump | Direct WiFi |
|---------|-----------|--------------|-----------|-----------|-------------|
| Works on cellular | Yes | Yes | Yes | Yes (via jump host) | No |
| Native SSH client | No | Yes | Yes | Yes | Yes |
| Setup complexity | Medium | High | Low | Low | None |
| Extra apps needed | None | 2 (1.1.1.1 + Termius) | 2 (Tailscale + Termius) | 1 (Termius) | 1 (Termius) |
| Auth layer | Cloudflare Access OTP | WARP Zero Trust | Tailscale account | SSH keys | None |
| Connection speed | Medium | Medium | Fast | Fast | Fastest |
| iOS VPN slot | No | Yes | Yes | No (uses jump host's) | No |
| File transfer | No | Yes (SCP/SFTP) | Yes (SCP/SFTP) | Yes (SCP/SFTP) | Yes (SCP/SFTP) |
| Reaches machines without VPN | No | No | No | Yes | N/A |
| Session persistence (tmux) | Manual | Manual | Manual | Manual | Manual |

## Resilience Layers

The methods above handle **connectivity**. These additional layers handle **reliability**:

| Layer | Purpose | Setup |
|-------|---------|-------|
| **tmux** | Process survives SSH drops | `tmux new -s <name>` before starting services |
| **Auto-tmux** | Never forget to start tmux | Add snippet to `~/.zshrc` (see [tmux guide](tmux-guide.md)) |
| **Launcher scripts** | One-click service recovery | `~/start-service.sh` (see [tmux guide](tmux-guide.md)) |
| **Claude Code** | AI-assisted debugging from phone | `claude --dangerously-skip-permissions` |
| **Address book** | Never lose a hostname/IP | Keep a table in your notes app |
