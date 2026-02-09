#!/bin/bash
#
# 03-setup-tailscale.sh
# Install and configure Tailscale for the simplest remote SSH experience
#
# What this does:
#   - Installs Tailscale on your Mac
#   - Creates a private WireGuard-based mesh network between your devices
#   - Each device gets a stable 100.x.x.x IP that works from anywhere
#   - No port forwarding, no configuration, no Cloudflare account needed
#
# Prerequisites:
#   - SSH enabled on your Mac (run 01-setup-mac-ssh.sh first)
#   - A Tailscale account (free for personal use)
#
# Usage: bash scripts/03-setup-tailscale.sh
#

set -e

echo "============================================"
echo "  Step 3: Tailscale Setup"
echo "============================================"
echo ""
echo "  Tailscale creates a private network (tailnet) between your devices"
echo "  using WireGuard encryption. It is the simplest way to get"
echo "  native SSH access to your Mac from anywhere."
echo ""
echo "  HOW IT WORKS:"
echo "  Your Phone (100.x.x.x) <--WireGuard--> Your Mac (100.x.x.x)"
echo "  Both devices get a stable IP that works over any network."
echo ""

# -----------------------------------------------
# Step 1: Install Tailscale
# -----------------------------------------------
echo "--- Step 3.1: Install Tailscale ---"
echo ""

if command -v tailscale &>/dev/null; then
    echo "[OK] Tailscale is already installed."
else
    echo "Choose installation method:"
    echo "  1. Homebrew (CLI only)"
    echo "  2. Mac App Store (GUI + CLI)"
    echo ""
    read -p "Enter choice (1 or 2): " install_method

    case $install_method in
        1)
            echo "Installing via Homebrew..."
            brew install tailscale
            echo "[OK] Tailscale CLI installed."
            ;;
        2)
            echo ""
            echo "Please install Tailscale from the Mac App Store:"
            echo "  1. Open App Store"
            echo "  2. Search for 'Tailscale'"
            echo "  3. Install it"
            echo ""
            read -p "Press Enter when installed..."
            ;;
        *)
            echo "Invalid choice. Please install manually."
            exit 1
            ;;
    esac
fi
echo ""

# -----------------------------------------------
# Step 2: Start and authenticate
# -----------------------------------------------
echo "--- Step 3.2: Start Tailscale ---"
echo ""

# Check if Tailscale is running
if tailscale status &>/dev/null; then
    echo "[OK] Tailscale is running."
else
    echo "Starting Tailscale..."
    echo "If using the App Store version, open the Tailscale app from your menu bar."
    echo "If using Homebrew, Tailscale should start automatically."
    echo ""
    read -p "Press Enter when Tailscale is running..."
fi
echo ""

# -----------------------------------------------
# Step 3: Get Tailscale IP
# -----------------------------------------------
echo "--- Step 3.3: Your Tailscale IP ---"
echo ""

TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "not available")
if [[ "$TAILSCALE_IP" != "not available" ]]; then
    echo "[OK] Your Mac's Tailscale IP: $TAILSCALE_IP"
else
    echo "[WARN] Could not get Tailscale IP. Make sure you're logged in."
    echo "  Run: tailscale login"
    echo ""
    read -p "Press Enter after logging in..."
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "check manually")
    echo "Tailscale IP: $TAILSCALE_IP"
fi
echo ""

# -----------------------------------------------
# Step 4: iPhone setup instructions
# -----------------------------------------------
echo "============================================"
echo "  iPhone Setup"
echo "============================================"
echo ""
echo "  1. Install 'Tailscale' from the App Store on your iPhone"
echo "  2. Open Tailscale and sign in with the SAME account"
echo "  3. Both devices should appear in your tailnet"
echo ""
echo "  Then in Termius (SSH app):"
echo "  - Host: $TAILSCALE_IP"
echo "  - Port: 22"
echo "  - Username: $(whoami)"
echo "  - Password: your Mac login password"
echo ""

# -----------------------------------------------
# Step 5: Verify
# -----------------------------------------------
echo "--- Verification ---"
echo ""
echo "Tailscale status:"
tailscale status 2>/dev/null || echo "  (run 'tailscale status' manually)"
echo ""

echo "============================================"
echo "  Tailscale Setup Complete!"
echo "============================================"
echo ""
echo "  Your Tailscale IP: $TAILSCALE_IP"
echo "  Username: $(whoami)"
echo ""
echo "  NOTE: Tailscale and Cloudflare WARP both use the iOS VPN slot."
echo "  You can only use ONE at a time on your iPhone."
echo ""
echo "  Run the verification script to test:"
echo "  bash scripts/04-verify-connection.sh"
echo ""
