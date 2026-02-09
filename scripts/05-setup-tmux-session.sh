#!/bin/bash
#
# 05-setup-tmux-session.sh
# Set up tmux for persistent remote sessions
#
# What this does:
#   - Installs tmux if not present
#   - Creates a service launcher script
#   - Optionally adds auto-tmux to .zshrc for SSH sessions
#
# Usage: bash scripts/05-setup-tmux-session.sh
#

set -e

echo "============================================"
echo "  Step 5: Tmux Session Persistence Setup"
echo "============================================"
echo ""
echo "  Tmux keeps your terminal sessions alive even when SSH drops."
echo "  This is critical for running services remotely."
echo ""

# -----------------------------------------------
# Step 1: Install tmux
# -----------------------------------------------
echo "--- Step 5.1: Install tmux ---"
echo ""

if command -v tmux &>/dev/null; then
    echo "[OK] tmux is already installed ($(tmux -V))."
else
    echo "Installing tmux..."
    if command -v brew &>/dev/null; then
        brew install tmux
        echo "[OK] tmux installed."
    else
        echo "[ERROR] Homebrew not found. Install tmux manually:"
        echo "  brew install tmux    (macOS)"
        echo "  apt install tmux     (Linux)"
        exit 1
    fi
fi
echo ""

# -----------------------------------------------
# Step 2: Create service launcher script
# -----------------------------------------------
echo "--- Step 5.2: Create service launcher ---"
echo ""

LAUNCHER_PATH="$HOME/start-service.sh"

if [[ -f "$LAUNCHER_PATH" ]]; then
    echo "[OK] Launcher script already exists at $LAUNCHER_PATH"
else
    cat > "$LAUNCHER_PATH" << 'SCRIPT'
#!/bin/bash
# Generic tmux service launcher
# Usage: ./start-service.sh <session-name> <command>
# Example: ./start-service.sh fastapi "cd ~/projects/my-api && source venv/bin/activate && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
# Example: ./start-service.sh jupyter "jupyter lab --port 8888"

SESSION="${1:?Usage: $0 <session-name> <command>}"
COMMAND="${2:?Usage: $0 <session-name> <command>}"

tmux has-session -t "$SESSION" 2>/dev/null
if [ $? != 0 ]; then
    tmux new-session -d -s "$SESSION"
    tmux send-keys -t "$SESSION" "$COMMAND" C-m
    echo "[OK] Started session '$SESSION' running: $COMMAND"
else
    echo "[OK] Session '$SESSION' already exists."
fi

echo "Attaching to session '$SESSION'..."
echo "(Detach with Ctrl+b d or 'tmux detach')"
echo ""
tmux attach -t "$SESSION"
SCRIPT

    chmod +x "$LAUNCHER_PATH"
    echo "[OK] Created launcher script at $LAUNCHER_PATH"
fi
echo ""

# -----------------------------------------------
# Step 3: Create fastapi-specific launcher
# -----------------------------------------------
echo "--- Step 5.3: Create FastAPI launcher (example) ---"
echo ""

FASTAPI_LAUNCHER="$HOME/start-fastapi.sh"

if [[ -f "$FASTAPI_LAUNCHER" ]]; then
    echo "[OK] FastAPI launcher already exists at $FASTAPI_LAUNCHER"
else
    cat > "$FASTAPI_LAUNCHER" << 'SCRIPT'
#!/bin/bash
# FastAPI service launcher with tmux
SESSION="fastapi"

tmux has-session -t $SESSION 2>/dev/null
if [ $? != 0 ]; then
    tmux new-session -d -s $SESSION
    tmux send-keys -t $SESSION "cd ~/projects/my-api && source venv/bin/activate && uvicorn main:app --host 0.0.0.0 --port 8000 --reload" C-m
    echo "[OK] Started FastAPI in tmux session '$SESSION'"
else
    echo "[OK] Session '$SESSION' already running."
fi

tmux attach -t $SESSION
SCRIPT

    chmod +x "$FASTAPI_LAUNCHER"
    echo "[OK] Created FastAPI launcher at $FASTAPI_LAUNCHER"
    echo "     Edit the paths inside to match your project."
fi
echo ""

# -----------------------------------------------
# Step 4: Auto-tmux for SSH sessions
# -----------------------------------------------
echo "--- Step 5.4: Auto-tmux on SSH login ---"
echo ""
echo "  This adds a snippet to ~/.zshrc that automatically starts tmux"
echo "  when you SSH in. You'll never accidentally run a service outside"
echo "  tmux again."
echo ""

ZSHRC="$HOME/.zshrc"
AUTO_TMUX_MARKER="# Auto-start tmux for SSH sessions"

if [[ -f "$ZSHRC" ]] && grep -q "$AUTO_TMUX_MARKER" "$ZSHRC"; then
    echo "[OK] Auto-tmux already configured in ~/.zshrc"
else
    read -p "Add auto-tmux to ~/.zshrc? (y/n): " add_auto_tmux
    if [[ "$add_auto_tmux" == "y" || "$add_auto_tmux" == "Y" ]]; then
        echo "" >> "$ZSHRC"
        cat >> "$ZSHRC" << 'SNIPPET'

# Auto-start tmux for SSH sessions
# When connecting via SSH, automatically enter a tmux session
# This ensures your processes survive disconnections
if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]]; then
    tmux attach -t main || tmux new -s main
fi
SNIPPET
        echo "[OK] Added auto-tmux to ~/.zshrc"
        echo "     Next SSH session will automatically start in tmux."
    else
        echo "[SKIP] Auto-tmux not added. You can add it manually later:"
        echo ""
        echo '  # Add to ~/.zshrc:'
        echo '  if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]]; then'
        echo '      tmux attach -t main || tmux new -s main'
        echo '  fi'
    fi
fi
echo ""

# -----------------------------------------------
# Step 5: Show current tmux sessions
# -----------------------------------------------
echo "--- Current tmux sessions ---"
echo ""
tmux ls 2>/dev/null || echo "  No active tmux sessions."
echo ""

# -----------------------------------------------
# Summary
# -----------------------------------------------
echo "============================================"
echo "  Tmux Setup Complete!"
echo "============================================"
echo ""
echo "  Launcher scripts:"
echo "    $LAUNCHER_PATH       (generic)"
echo "    $FASTAPI_LAUNCHER    (FastAPI example)"
echo ""
echo "  Quick reference:"
echo "    tmux new -s <name>      Create a session"
echo "    tmux attach -t <name>   Attach to a session"
echo "    tmux ls                 List sessions"
echo "    Ctrl+b d               Detach (keep running)"
echo "    tmux detach             Detach (Warp-friendly)"
echo ""
echo "  See docs/tmux-guide.md for full documentation."
echo ""
