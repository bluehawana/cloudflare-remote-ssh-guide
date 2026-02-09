# LinkedIn Post Draft

---

**New Year New Project #6: Remote SSH to My Mac Mini M4 From Anywhere**

I wanted a simple thing: SSH into my Mac Mini M4 from my iPhone while sitting in a coffee shop. Sounds easy, right?

It wasn't. But after a long debugging session, I ended up with 4 different ways to do it. Here's what I learned.

**The Goal:**
Access my home Mac Mini remotely from my iPhone using Termius, without exposing any ports or using traditional VPNs.

**The Solution: Cloudflare Tunnel + Zero Trust**

Cloudflare Tunnel creates a secure outbound connection from your Mac to Cloudflare's edge. No port forwarding. No public IP needed. No firewall holes.

I set up 4 connection methods:

1. **Browser SSH via Cloudflare Access** - Open Safari, go to ssh.mydomain.com, authenticate with email OTP, get a terminal. Zero apps needed.

2. **Cloudflare WARP + Termius** - Native SSH from Termius over cellular using Cloudflare's private network routing. This was the hardest to set up.

3. **Tailscale + Termius** - Install Tailscale on both devices, sign in, SSH to the Tailscale IP. Done in 5 minutes.

4. **Direct WiFi** - The classic. SSH to the local IP when on the same network.

**The Hard-Earned Lessons:**

- Cloudflare's Gateway proxy must be explicitly turned ON (Traffic policies > Traffic settings). Without it, WARP connects but `is_gateway` stays `false` and private network routing silently fails.

- `warp-routing: enabled` must be in your cloudflared config.yml - without it, the tunnel only handles hostname-based routing, not private IPs.

- Browser rendering must be set to "SSH" in the Cloudflare Access app settings. If left as "Disabled", your browser downloads a text file instead of showing a terminal.

- iOS only allows one VPN at a time. Tailscale and WARP can't coexist.

- The WARP iOS client can be stubborn about syncing config changes. Sometimes a full app reinstall + re-enrollment is the only fix.

- When all else fails, check the basics: Is Remote Login enabled? Is the tunnel actually running? `tail -f /Library/Logs/com.cloudflare.cloudflared.err.log`

**My take:**

For quick mobile access, Tailscale wins on simplicity. For a zero-install browser terminal, Cloudflare's browser SSH is brilliant. For the full Cloudflare Zero Trust experience with native SSH, WARP works but requires patience with the iOS client.

The complete step-by-step guide with configs, architecture diagrams, and troubleshooting:

https://github.com/bluehawana/cloudflare-remote-ssh-guide

#CloudflareZeroTrust #RemoteAccess #SSH #Tailscale #MacMiniM4 #DevOps #Networking #NewYearNewProject #HomeLab #CloudflareTunnel

---
