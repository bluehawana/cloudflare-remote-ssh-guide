# Method 1: Direct WiFi SSH (Home Network Only)

> The simplest method. Same WiFi network, direct SSH connection.

---

## How It Works

```
+------------------+                                     +------------------+
|   iPhone         |          Local Network (WiFi)       |    Your Mac      |
|                  +------------------------------------>+                  |
|  Termius App     |          192.168.1.x/24             |  192.168.1.x     |
|  SSH to          |<------------------------------------+       |          |
|  192.168.1.x     |                                     |       v          |
|                  |                                     |  SSH localhost:22 |
+------------------+                                     +------------------+
```

## Setup

### 1. Enable SSH on your Mac

```bash
# Check if SSH is running
nc -z localhost 22 && echo "SSH is running"

# Or run the setup script
bash scripts/01-setup-mac-ssh.sh
```

Or manually: **System Settings > General > Sharing > Remote Login > ON**

### 2. Find your Mac's local IP

```bash
ipconfig getifaddr en0
# Example output: 192.168.1.x
```

Or: hold **Option** + click the WiFi icon in the menu bar.

### 3. Connect from Termius on your phone

| Field | Value |
|-------|-------|
| Host | `192.168.1.x` (your Mac's IP) |
| Port | `22` |
| Username | your Mac username |
| Password | your Mac login password |

![Termius Hosts](../resources/06-termius-hosts.jpeg)
*Termius host configuration -- one entry per connection method.*

## Result

![WiFi Direct SSH](../resources/01-wifi-direct-ssh.jpeg)
*SSH connection from iPhone to Mac Mini over home WiFi using Termius.*

## Limitation

This only works when both devices are on the same network. Step outside your home, and the connection drops. That's where Methods 2-5 come in.
