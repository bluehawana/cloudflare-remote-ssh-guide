# Tmux: Session Persistence for Remote Services

> If you SSH into a machine and run a service in the foreground, the moment your SSH connection drops, so does the service. Tmux prevents this.

---

## Why Tmux Matters

Without tmux:
```
SSH connects → start service → SSH drops → service DIES
```

With tmux:
```
SSH connects → tmux session → start service → SSH drops → service KEEPS RUNNING
                                                            ↓
                                              SSH reconnects → tmux attach → right where you left off
```

Tmux runs sessions independently of your SSH connection. Even if your network cuts out, the service keeps running. When you reconnect, `tmux attach` brings you right back.

---

## Quick Start

### Create a session and start a service

```bash
tmux new -s fastapi                      # Create a named session
cd ~/projects/my-api
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Detach (leave session running)

```bash
# Press Ctrl+b, then d
# Or type:
tmux detach
```

> **Warp terminal users:** `Ctrl+b d` may be intercepted by Warp. Use the `tmux detach` command instead.

### Reattach later

```bash
tmux attach -t fastapi
```

---

## Essential Commands

| Action | Command |
|--------|---------|
| New session | `tmux new -s <name>` |
| List sessions | `tmux ls` |
| Attach to session | `tmux attach -t <name>` |
| Detach from session | `Ctrl+b d` or `tmux detach` |
| Kill session | `tmux kill-session -t <name>` |
| New window | `Ctrl+b c` |
| Switch window | `Ctrl+b <number>` |
| Split horizontally | `Ctrl+b "` |
| Split vertically | `Ctrl+b %` |
| Navigate panes | `Ctrl+b <arrow>` |
| Scroll mode | `Ctrl+b [` (then arrow keys, `q` to exit) |

---

## Automation Scripts

### One-Click Service Launcher

Save this as `~/start-fastapi.sh` on your server. It creates the tmux session if it doesn't exist, or attaches to it if it does:

```bash
#!/bin/bash
SESSION="fastapi"

tmux has-session -t $SESSION 2>/dev/null
if [ $? != 0 ]; then
    tmux new-session -d -s $SESSION
    tmux send-keys -t $SESSION "cd ~/projects/my-api && source venv/bin/activate && uvicorn main:app --host 0.0.0.0 --port 8000 --reload" C-m
fi

tmux attach -t $SESSION
```

Usage:
```bash
chmod +x ~/start-fastapi.sh
~/start-fastapi.sh
```

### Auto-Tmux on SSH Login

Add this to `~/.zshrc` (or `~/.bashrc`) on the remote machine. Every SSH connection automatically enters a tmux session:

```bash
# Auto-start tmux for SSH sessions
if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]]; then
    tmux attach -t main || tmux new -s main
fi
```

This means:
- SSH in → you're automatically in tmux
- Disconnect → session persists
- SSH back in → you're right where you left off

No more forgetting to start tmux and losing your session.

### Generic Service Launcher Template

A reusable script for any service:

```bash
#!/bin/bash
# Usage: ./start-service.sh <session-name> <command>
# Example: ./start-service.sh my-api "uvicorn main:app --reload"
# Example: ./start-service.sh jupyter "jupyter lab --port 8888"

SESSION="${1:?Usage: $0 <session-name> <command>}"
COMMAND="${2:?Usage: $0 <session-name> <command>}"

tmux has-session -t "$SESSION" 2>/dev/null
if [ $? != 0 ]; then
    tmux new-session -d -s "$SESSION"
    tmux send-keys -t "$SESSION" "$COMMAND" C-m
    echo "Started '$SESSION' running: $COMMAND"
else
    echo "Session '$SESSION' already exists."
fi

echo "Attaching..."
tmux attach -t "$SESSION"
```

---

## Best Practices

1. **Always name your sessions** -- `tmux new -s api` is much better than `tmux new` when you have multiple sessions
2. **Use the auto-tmux snippet** -- you'll never forget to start tmux again
3. **One service per session** -- keeps things organized and easy to manage
4. **Use the launcher script** -- idempotent: safe to run multiple times without duplicating sessions
5. **Check sessions before leaving** -- `tmux ls` to see what's running before you disconnect

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| `tmux: command not found` | `brew install tmux` (macOS) or `apt install tmux` (Linux) |
| `no server running` | No tmux sessions exist; create one with `tmux new -s <name>` |
| `sessions should be nested` | You're already in tmux; detach first with `Ctrl+b d` |
| Ctrl+b not working in Warp | Use `tmux detach` command instead |
| Lost scroll history | Enter scroll mode with `Ctrl+b [`, exit with `q` |

---

*Tmux is your process insurance policy. The five seconds it takes to start a named session can save you hours of re-setup when your connection drops.*
