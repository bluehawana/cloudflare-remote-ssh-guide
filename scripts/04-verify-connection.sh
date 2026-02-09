#!/bin/bash
#
# 04-verify-connection.sh
# Verify that all remote SSH connection methods are working
#
# Usage: bash scripts/04-verify-connection.sh
#

echo "============================================"
echo "  Connection Verification"
echo "============================================"
echo ""

PASS=0
FAIL=0
SKIP=0

check() {
    local name="$1"
    local result="$2"
    if [[ "$result" == "ok" ]]; then
        echo "  [PASS] $name"
        ((PASS++))
    elif [[ "$result" == "skip" ]]; then
        echo "  [SKIP] $name"
        ((SKIP++))
    else
        echo "  [FAIL] $name"
        ((FAIL++))
    fi
}

# -----------------------------------------------
# Check 1: SSH Server
# -----------------------------------------------
echo "--- 1. SSH Server ---"
if nc -z localhost 22 2>/dev/null; then
    check "SSH listening on port 22" "ok"
else
    check "SSH listening on port 22" "fail"
fi
echo ""

# -----------------------------------------------
# Check 2: Local Network (WiFi Direct)
# -----------------------------------------------
echo "--- 2. Direct WiFi (Method 1) ---"
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "")
if [[ -n "$LOCAL_IP" ]]; then
    check "WiFi connected (IP: $LOCAL_IP)" "ok"
    if nc -z "$LOCAL_IP" 22 2>/dev/null; then
        check "SSH reachable at $LOCAL_IP:22" "ok"
    else
        check "SSH reachable at $LOCAL_IP:22" "fail"
    fi
else
    check "WiFi connected" "fail"
fi
echo ""

# -----------------------------------------------
# Check 3: Cloudflare Tunnel
# -----------------------------------------------
echo "--- 3. Cloudflare Tunnel (Methods 2 & 3) ---"
if command -v cloudflared &>/dev/null; then
    check "cloudflared installed ($(cloudflared --version 2>&1 | head -1))" "ok"

    # Check if tunnel is running
    if pgrep -x cloudflared >/dev/null; then
        check "cloudflared process running" "ok"
    else
        check "cloudflared process running" "fail"
        echo "         Fix: sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist"
    fi

    # Check config
    if [[ -f "$HOME/.cloudflared/config.yml" ]]; then
        check "Config file exists" "ok"

        # Check warp-routing
        if grep -q "warp-routing" "$HOME/.cloudflared/config.yml" && grep -A1 "warp-routing" "$HOME/.cloudflared/config.yml" | grep -q "enabled: true"; then
            check "WARP routing enabled in config" "ok"
        else
            check "WARP routing enabled in config" "fail"
            echo "         Fix: Add 'warp-routing: enabled: true' to config.yml"
        fi
    else
        check "Config file exists" "fail"
        echo "         Fix: Run bash scripts/02-setup-cloudflared.sh"
    fi

    # Check tunnel list
    echo ""
    echo "  Active tunnels:"
    cloudflared tunnel list 2>/dev/null | head -5 || echo "  (could not list tunnels)"

    # Check route
    echo ""
    echo "  Private network routes:"
    cloudflared tunnel route ip show 2>/dev/null | head -5 || echo "  (could not show routes)"

    # Check logs
    echo ""
    echo "  Recent tunnel logs:"
    if [[ -f /Library/Logs/com.cloudflare.cloudflared.err.log ]]; then
        tail -3 /Library/Logs/com.cloudflare.cloudflared.err.log 2>/dev/null
    else
        echo "  (no log file found)"
    fi
else
    check "cloudflared installed" "skip"
    echo "         Not installed. Run: bash scripts/02-setup-cloudflared.sh"
fi
echo ""

# -----------------------------------------------
# Check 4: Tailscale
# -----------------------------------------------
echo "--- 4. Tailscale (Method 4) ---"
if command -v tailscale &>/dev/null; then
    check "Tailscale installed" "ok"

    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
    if [[ -n "$TAILSCALE_IP" ]]; then
        check "Tailscale connected (IP: $TAILSCALE_IP)" "ok"
    else
        check "Tailscale connected" "fail"
        echo "         Fix: Open Tailscale app and sign in"
    fi

    echo ""
    echo "  Tailscale status:"
    tailscale status 2>/dev/null | head -5 || echo "  (not running)"
else
    check "Tailscale installed" "skip"
    echo "         Not installed. Run: bash scripts/03-setup-tailscale.sh"
fi
echo ""

# -----------------------------------------------
# Summary
# -----------------------------------------------
echo "============================================"
echo "  Summary"
echo "============================================"
echo ""
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Skipped: $SKIP"
echo ""

if [[ $FAIL -eq 0 ]]; then
    echo "  All checks passed! Your Mac is ready for remote SSH."
else
    echo "  Some checks failed. Review the [FAIL] items above."
fi

echo ""
echo "============================================"
echo "  Quick Connection Reference"
echo "============================================"
echo ""
echo "  Method 1 - WiFi Direct:     ssh $(whoami)@${LOCAL_IP:-your-wifi-ip}"
echo "  Method 2 - Browser SSH:     https://ssh.yourdomain.com"
echo "  Method 3 - WARP + Termius:  ssh $(whoami)@${LOCAL_IP:-your-wifi-ip} (via WARP VPN)"
echo "  Method 4 - Tailscale:       ssh $(whoami)@${TAILSCALE_IP:-your-tailscale-ip}"
echo ""
