# Pre-Travel Checklist: Secure Your Remote Access Before Leaving Home

> Holiday coming up? Business trip? Spend 30 minutes setting these up before you leave. Your future self will thank you.

---

## The Checklist

### 1. Tailscale: Your Key Back Home

Install Tailscale on **at least one machine** at home. This is your tunnel from the outside world to your home network.

```bash
brew install tailscale
# Then open the app and sign in
```

- [ ] Tailscale installed on at least one home machine
- [ ] Tailscale installed on your phone
- [ ] Both signed into the same account
- [ ] Test: `ssh user@machine-name` works via Tailscale from your phone

**Why at least one?** If only one machine has Tailscale, you can use it as a [jump host](ssh-config-proxyjump.md) to reach the others. Zero machines with Tailscale = zero paths home.

### 2. Know Your Addresses

Record the addresses of every machine you might need to reach:

| Machine | Local IP | .local Hostname | Tailscale IP |
|---------|----------|----------------|-------------|
| Mac Studio | `192.168.1.___` | `___.local` | `100.___.___.___` |
| Mac Mini | `192.168.1.___` | `___.local` | `100.___.___.___` |

How to find these:

```bash
# Local IP
ipconfig getifaddr en0

# .local hostname (macOS Bonjour/mDNS)
scutil --get LocalHostName
# Result + ".local" = your hostname, e.g., mac-mini.local

# Tailscale IP
tailscale ip -4
```

- [ ] Local IPs recorded
- [ ] `.local` hostnames recorded
- [ ] Tailscale IPs recorded
- [ ] Saved somewhere accessible from your phone (notes app, password manager)

### 3. SSH Config with ProxyJump

Set up `~/.ssh/config` so you can reach any machine with a single command:

```ssh-config
Host mac-studio
    HostName mac-studio
    User youruser

Host mac-mini
    HostName mac-mini.local
    User youruser
    ProxyJump mac-studio
```

- [ ] SSH config file created/updated
- [ ] Jump host entries configured
- [ ] Test: `ssh mac-mini` works (goes through jump host automatically)

See [SSH Config & ProxyJump Guide](ssh-config-proxyjump.md) for details.

### 4. Services Running in Tmux

Every long-running service should be in a tmux session:

```bash
tmux new -s my-service
# start your service here
# Ctrl+b d to detach
```

- [ ] All services running in named tmux sessions
- [ ] Auto-tmux snippet added to `~/.zshrc` on remote machines
- [ ] Launcher scripts created for critical services
- [ ] Test: disconnect SSH, reconnect, `tmux attach` recovers session

See [Tmux Guide](tmux-guide.md) for automation scripts.

### 5. Phone Ready

- [ ] **Termius** installed with all hosts pre-configured
- [ ] **Tailscale** app installed and signed in
- [ ] **Claude Code** installed on remote machines (`npm install -g @anthropic-ai/claude-code`)
- [ ] **Voice input** app installed (Typeless or similar)
- [ ] Full test: SSH from phone → tmux attach → run a command → detach

### 6. SSH Enabled on All Machines

On macOS:
```bash
# Check if SSH is running
nc -z localhost 22 && echo "SSH is running" || echo "SSH is NOT running"
```

If not running:
- System Settings → General → Sharing → Remote Login → ON

- [ ] SSH (Remote Login) enabled on all machines
- [ ] Tested from another device

---

## Quick Verification

Run the verification script to check everything:

```bash
bash scripts/04-verify-connection.sh
```

---

## The 30-Minute Setup

| Time | Task |
|------|------|
| 0-5 min | Install Tailscale on all machines, sign in |
| 5-10 min | Record all IPs and hostnames |
| 10-15 min | Set up `~/.ssh/config` with ProxyJump |
| 15-20 min | Move services into tmux sessions |
| 20-25 min | Add auto-tmux to `.zshrc`, create launcher scripts |
| 25-30 min | Set up phone (Termius hosts, test connections) |

---

## What Happens If You Skip This

| Scenario | With Prep | Without Prep |
|----------|-----------|-------------|
| Service crashes at 2 AM | SSH from phone, fix in 5 min | Wait until you get home |
| Need to check logs | `ssh mac-mini`, `tmux attach`, done | "What was the IP again?" |
| Network change at home | Tailscale doesn't care about IP changes | Connection lost, no way back |
| SSH drops mid-session | Tmux keeps session alive, reconnect | Process died, start over |

---

*30 minutes of preparation vs. days of downtime. The math is simple.*
