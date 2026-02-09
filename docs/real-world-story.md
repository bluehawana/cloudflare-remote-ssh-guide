# Real-World Story: Remote Firefighting From a Hotel Bed

> A service crashed on a home Mac Mini while the operator was on vacation. This is how it got fixed in 5 minutes -- from a phone, in a hotel bed.

---

## The Scenario

You're away from home. A monitoring alert fires: a service on your home Mac Mini is down. No laptop with you. And the Mac Mini doesn't have Tailscale or Cloudflare Tunnel installed.

If you had set up Cloudflare Zero Trust (Method 2 or 3 from this guide), you could connect directly from any browser or via WARP. But not every machine in your home lab will have the full tunnel setup. That's where the **jump host pattern** saves the day.

## The Fix: Jump Host + Zero Trust

The approach: route through a machine that *does* have remote access configured.

```
[Phone on hotel WiFi] → Tailscale/CF WARP → [Mac Studio] → LAN SSH → [Mac Mini]
```

With Cloudflare Zero Trust, you could also do:

```
[Phone browser] → https://ssh.yourdomain.com → [Mac Studio] → ssh mac-mini.local
```

Either way, the Mac Studio acts as a bridge to machines on the home LAN that don't have their own external access.

### Step 1: Connect to the jump host

```bash
ssh user@mac-studio  # Via Tailscale, or through Cloudflare WARP
```

### Step 2: Hop to the target machine

```bash
ssh user@mac-mini.local  # macOS Bonjour/mDNS -- no IP needed
```

With SSH ProxyJump configured, this becomes a single command: `ssh mac-mini`

### Step 3: Recover the service

```bash
tmux attach -t fastapi
# Service had exited -- restart it
uvicorn main:app --reload
```

Total time: under five minutes.

## What Had To Be In Place

This recovery required three things. Without any one of them, it would have failed:

| # | Requirement | Without It |
|---|------------|-------------|
| 1 | At least one machine with external access (Tailscale, CF Tunnel, WARP) | No way to reach the home network at all |
| 2 | Target machine's address recorded (.local hostname or IP) | Jump host is useless without a destination |
| 3 | Service running inside tmux | Process would have died with the previous SSH session |

**The difference between "fix in 5 minutes" and "wait until you get home" is preparation.**

## The Lesson

> Backup isn't just about data. It's about keeping a path home.

With Cloudflare Zero Trust, you get a more secure and reliable path than simple Tailscale -- email-authenticated, no open ports, works from any browser. But even the best tunnel is useless if:

- You didn't install it on the right machine
- Your service wasn't running in tmux
- You don't know the target machine's address

The rest of this guide turns ad-hoc "got lucky" into deliberate infrastructure. Every section -- Cloudflare Tunnel, Tailscale, tmux, SSH ProxyJump, the pre-travel checklist -- eliminates one more point of failure.

## The Mobile + AI Twist

The entire rescue happened on a phone. No laptop.

- **Termius** on iPhone for SSH
- **Claude Code** in `--dangerously-skip-permissions` mode for hands-free debugging
- **Voice input** to type commands without fumbling on a tiny keyboard

One voice command: *"Check why the fastapi service is down and restart it."*

Claude Code checked the logs, found the error, and restarted the service. All while the operator was lying in bed.

See [Mobile + AI Workflow](mobile-ai-workflow.md) for the full setup.

---

*This story is the reason the [Pre-Travel Checklist](pre-travel-checklist.md) exists. Set it up before you leave home -- not after something breaks.*
