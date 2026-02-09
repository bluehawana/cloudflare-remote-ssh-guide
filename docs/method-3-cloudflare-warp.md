# Method 3: Cloudflare WARP + Termius (Native SSH, Any Network)

> Native SSH from your phone over cellular using Cloudflare's private network routing. The hardest to configure, but the full Zero Trust experience.

---

## How It Works

```
+------------------+        +-------------------+        +------------------+
|   iPhone         |  WARP  |  Cloudflare Edge  |  QUIC  |    Your Mac      |
|                  +------->+                   +------->+                  |
|  1.1.1.1 App     |  VPN   |  Gateway Proxy    |        |  cloudflared     |
|  (Zero Trust)    |  Tunnel|  Split Tunnel      |        |  (warp-routing)  |
|       +          |        |  Route: 192.168.x  |        |       |          |
|  Termius App     |        |  -> tunnel         |        |       v          |
|  SSH to          |<-------+                   |<-------+  SSH localhost:22 |
|  192.168.1.x     |  WARP  |                   |  QUIC  |                  |
+------------------+        +-------------------+        +------------------+
```

## Prerequisites

- Cloudflare Tunnel already set up (see [Method 2](method-2-cloudflare-browser-ssh.md))
- `warp-routing: enabled` in your `config.yml`

## Dashboard Configuration

> This is the hardest method to set up. The interactive guide helps:
> ```bash
> bash scripts/02b-configure-zero-trust.sh
> ```

### The critical steps most people miss:

#### 1. Enable Gateway Proxy
**Traffic policies > Traffic settings**
- Turn ON "Allow Secure Web Gateway to proxy traffic"
- Enable TCP, UDP, ICMP
- *Without this, `is_gateway` stays `false` and everything silently fails*

#### 2. Fix Split Tunnels
**Devices > Device profiles > Default**
- REMOVE `192.168.0.0/16` from the exclude list
- *This tells WARP to route your home network IPs through the tunnel*

![Cloudflare Dashboard](../resources/07-cloudflare-dashboard.png)
*Cloudflare Zero Trust device profile settings -- Split Tunnels configuration.*

#### 3. Add Gateway Network Policy
**Traffic policies > Network**
- Destination IP `in` `YOUR_MAC_IP/32` -> Allow
- *Explicitly permits traffic to your Mac*

#### 4. Add private network route

```bash
cloudflared tunnel route ip add YOUR_MAC_IP/32 mac-remote
```

## iPhone Setup

1. Install **"1.1.1.1: Faster Internet"** from App Store
2. Open > Settings > Account > **Login to Cloudflare Zero Trust**
3. Enter your Zero Trust organization name
4. Install the VPN profile when prompted
5. Enter Zero Trust mode first, then connect WARP

## Connect with Termius

| Field | Value |
|-------|-------|
| Host | `192.168.1.x` (your Mac's local IP) |
| Port | `22` |
| Username | your Mac username |
| Password | your Mac login password |

## Result

![5G WARP SSH](../resources/02-cellular-5g-warp-ssh.jpeg)
*SSH connection from iPhone over 5G cellular via Cloudflare WARP. Notice the 5G indicator -- this is not on WiFi.*

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `is_gateway: false` | Enable Gateway proxy in Traffic policies > Traffic settings |
| Config not syncing to iOS | Log out of Zero Trust, delete app, reinstall, re-enroll |
| "Could not establish connection" | Turn off other VPN apps (Tailscale, Shadowrocket) first |
| Split tunnel not updating | Delete old device registrations in Devices |
| WARP keeps disconnecting | Enter Zero Trust mode first, then toggle connection on |

See also: [Gateway Network Policy Setup](gateway-network-policy.md)
