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
|  192.168.1.216   |  WARP  |                   |  QUIC  |                  |
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
|       +          |        |  (or direct P2P)  |        |  100.113.182.107 |
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
|  Termius App     |          192.168.1.x/24             |  192.168.1.216   |
|  SSH to          |<------------------------------------+       |          |
|  192.168.1.216   |                                     |       v          |
|                  |                                     |  SSH localhost:22 |
+------------------+                                     +------------------+
```

- Only works on the same network
- No tunnel or VPN needed
- Fastest connection (no overhead)

## Comparison

| Feature | Browser SSH | WARP+Termius | Tailscale | Direct WiFi |
|---------|-----------|--------------|-----------|-------------|
| Works on cellular | Yes | Yes | Yes | No |
| Native SSH client | No | Yes | Yes | Yes |
| Setup complexity | Medium | High | Low | None |
| Extra apps needed | None | 2 (1.1.1.1 + Termius) | 2 (Tailscale + Termius) | 1 (Termius) |
| Auth layer | Cloudflare Access OTP | WARP Zero Trust | Tailscale account | None |
| Connection speed | Medium | Medium | Fast | Fastest |
| iOS VPN slot | No | Yes | Yes | No |
| File transfer | No | Yes (SCP/SFTP) | Yes (SCP/SFTP) | Yes (SCP/SFTP) |
