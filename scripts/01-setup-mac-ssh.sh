#!/bin/bash
#
# 01-setup-mac-ssh.sh
# Enable and configure SSH (Remote Login) on your Mac
# This is the FIRST step before any remote connection method works.
#
# Usage: bash scripts/01-setup-mac-ssh.sh
#

set -e

echo "============================================"
echo "  Step 1: Enable SSH on Your Mac"
echo "============================================"
echo ""
echo "SSH (Secure Shell) lets other devices connect to your Mac's terminal."
echo "macOS has a built-in SSH server -- you just need to turn it on."
echo ""

# Check if SSH is already running
if systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
    echo "[OK] Remote Login (SSH) is already enabled."
    echo ""
else
    echo "[ACTION REQUIRED] Remote Login is NOT enabled."
    echo ""
    echo "To enable it:"
    echo "  1. Open System Settings"
    echo "  2. Go to General > Sharing"
    echo "  3. Turn ON 'Remote Login'"
    echo "  4. Allow access for your user (or all users)"
    echo ""
    echo "Or run this command (requires admin password):"
    echo "  sudo systemsetup -setremotelogin on"
    echo ""
    read -p "Would you like to enable it now? (y/n): " enable_ssh
    if [[ "$enable_ssh" == "y" || "$enable_ssh" == "Y" ]]; then
        sudo systemsetup -setremotelogin on
        echo "[OK] Remote Login enabled."
    else
        echo "[SKIP] Please enable Remote Login manually before continuing."
    fi
fi

# Verify SSH is listening
echo "--- Verifying SSH is running ---"
if nc -z localhost 22 2>/dev/null; then
    echo "[OK] SSH server is listening on port 22."
else
    echo "[ERROR] SSH is not responding on port 22."
    echo "  Make sure Remote Login is ON in System Settings > General > Sharing."
    exit 1
fi

# Show connection info
echo ""
echo "============================================"
echo "  Your Mac's Connection Info"
echo "============================================"
echo ""
echo "Username:  $(whoami)"
echo "Hostname:  $(hostname)"

# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "not connected")
echo "WiFi IP:   $LOCAL_IP"
echo "SSH Port:  22"
echo ""
echo "To connect from another device on the same WiFi:"
echo "  ssh $(whoami)@$LOCAL_IP"
echo ""
echo "============================================"
echo "  Next Steps"
echo "============================================"
echo ""
echo "You now have 4 ways to connect to this Mac:"
echo ""
echo "  Method 1: Direct WiFi (same network only)"
echo "    -> No extra setup needed. Use the WiFi IP above."
echo ""
echo "  Method 2: Cloudflare Browser SSH (any network, no app needed)"
echo "    -> Run: bash scripts/02-setup-cloudflared.sh"
echo ""
echo "  Method 3: Cloudflare WARP + Termius (any network, native SSH)"
echo "    -> Run: bash scripts/02-setup-cloudflared.sh (includes WARP setup)"
echo ""
echo "  Method 4: Tailscale + Termius (any network, simplest)"
echo "    -> Run: bash scripts/03-setup-tailscale.sh"
echo ""
