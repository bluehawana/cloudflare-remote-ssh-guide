# Mobile + AI Workflow: Fix Servers From Your Phone

> No laptop? No problem. SSH from your phone, let AI do the typing.

---

## The Setup

When you're away from home with only your phone, you need three things:

1. **A way in** -- SSH client on your phone
2. **A way to work** -- AI agent that can run commands for you
3. **A way to talk** -- Voice input so you're not pecking at a tiny keyboard

```
Voice → Typeless → Claude Code → Server Fixed
         (speech     (AI agent      (reads logs,
          to text)    runs cmds)     restarts service)
```

---

## Tool 1: Termius (Mobile SSH Client)

[Termius](https://termius.com/) is the best SSH client for phones. Available on iOS and Android, free tier works fine.

### Setup Before You Leave Home

Configure your hosts **before** you need them:

| Field | Value |
|-------|-------|
| Label | `mac-mini` (or whatever you want) |
| Host | Your Tailscale IP (`100.x.x.x`) or `.local` hostname |
| Port | `22` |
| Username | Your Mac username |
| Password | Your Mac login password |

**Pro tip:** Set up multiple hosts -- one via Tailscale IP, one via local IP, one via ProxyJump. If one path is down, try another.

### Connecting

1. Open Termius
2. Tap the host
3. You're in a terminal

That's it. Full SSH session from your phone.

---

## Tool 2: Claude Code (AI Terminal Agent)

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is Anthropic's CLI tool that can read files, run commands, and debug issues autonomously.

### Pre-Install on Your Server

Install Claude Code on every machine you might need to access remotely:

```bash
npm install -g @anthropic-ai/claude-code
```

### Auto Mode for Mobile

When you're on a phone, you don't want to approve every single command. Set up auto mode:

```bash
claude --dangerously-skip-permissions
```

> **Warning:** This mode executes commands without confirmation. Only use it on machines where you trust the AI to make decisions, and only during active troubleshooting sessions.

### Example: Voice-Driven Debugging

You SSH in from your phone, start Claude Code, and say (via voice input):

> "Check why the fastapi service is down and restart it"

Claude Code will:
1. Check running processes (`ps aux | grep uvicorn`)
2. Read recent logs
3. Identify the error
4. Restart the service
5. Verify it's running

All without you typing a single command on that tiny phone keyboard.

---

## Tool 3: Typeless (Voice Input)

[Typeless](https://typeless.ch/) converts speech to text on your phone. Instead of typing commands or instructions, speak them.

### Why Voice Input Matters on Mobile

- Phone keyboards are painful for technical content
- SSH sessions show monospace text that's hard to read on small screens
- Voice lets you give high-level instructions instead of exact commands
- Combined with Claude Code, you're essentially giving verbal orders to an AI

### Workflow

1. Open Termius → SSH into your server
2. Start `claude --dangerously-skip-permissions`
3. Switch to Typeless → speak your instruction
4. Copy the transcribed text → paste into Claude Code
5. Watch it work

---

## Complete Mobile Emergency Workflow

### Before the Emergency (Set Up at Home)

- [ ] Install Termius on your phone, configure all hosts
- [ ] Install Claude Code on your servers (`npm install -g @anthropic-ai/claude-code`)
- [ ] Install Typeless on your phone for voice input
- [ ] Test the full flow: phone → SSH → Claude Code → run a command
- [ ] Set up tmux auto-start (see [tmux guide](tmux-guide.md))

### During the Emergency

```
1. Get the alert on your phone
2. Open Termius → tap the host → SSH in
3. tmux attach (or auto-tmux catches you)
4. claude --dangerously-skip-permissions
5. Voice: "Check what's wrong with [service] and fix it"
6. Verify the fix
7. tmux detach → close Termius
8. Go back to sleep
```

### Real Example

> Lying in a hotel bed, kid sleeping next to me. Phone alert: fastapi service down.
>
> Opened Termius, SSH'd into Mac Studio via Tailscale, jumped to Mac Mini.
> Started Claude Code. Said: "fastapi service crashed, check logs and restart it."
>
> Claude checked the logs, found a dependency error, restarted the service.
> Total time: 5 minutes. Never left the bed.

---

## Alternative Tools

| Tool | Purpose | Platform | Notes |
|------|---------|----------|-------|
| **Termius** | SSH client | iOS, Android | Best mobile SSH experience |
| **Blink Shell** | SSH client | iOS | Good alternative, more Unix-native |
| **Prompt 3** | SSH client | iOS | By Panic, clean UI |
| **JuiceSSH** | SSH client | Android | Best free Android option |
| **Claude Code** | AI terminal agent | Any (via SSH) | Runs on the server, not the phone |
| **Typeless** | Voice to text | iOS, Android | AI-powered transcription |
| **iOS Dictation** | Voice to text | iOS | Built-in, works in a pinch |

---

*The phone in your pocket is a remote control for every server you own. Set up the tools before you need them, and "remote emergency" becomes "minor inconvenience."*
