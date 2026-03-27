#!/usr/bin/env bash
# =============================================================================
# run_bot.sh — Build and run the Azalea bot
#
# Usage:
#   ./run_bot.sh                             # offline, localhost:25566
#   ./run_bot.sh -s 10.0.0.5 -p 25566       # offline, remote server
#   ./run_bot.sh -e user@example.com         # Microsoft auth
#   ./run_bot.sh -c config.toml              # use config file
#
# All flags are passed through to the bot binary. Run with --help for details.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOT_DIR="$SCRIPT_DIR/bot"

echo "=== Building Azalea Bot ==="
cd "$BOT_DIR"
cargo build --release 2>&1

echo ""
echo "=== Running Azalea Bot ==="
exec ./target/release/azalea-bot "$@"
