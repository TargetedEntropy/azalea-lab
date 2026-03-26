#!/usr/bin/env bash
# =============================================================================
# run_bot.sh — Build and run the Azalea bot
#
# Connects to the MC server and sends "azalea-bot online" in chat.
#
# Usage:
#   ./run_bot.sh                    # connect to localhost:25566
#   MC_HOST=10.0.0.5 ./run_bot.sh  # connect to a remote host
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOT_DIR="$SCRIPT_DIR/bot"

MC_HOST="${MC_HOST:-localhost}"
MC_PORT="${MC_PORT:-25566}"

echo "=== Building Azalea Bot ==="
cd "$BOT_DIR"
cargo build --release 2>&1

echo ""
echo "=== Running Azalea Bot ==="
echo "Connecting to ${MC_HOST}:${MC_PORT}..."
cargo run --release 2>&1
