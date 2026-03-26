#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BOT_DIR="$REPO_DIR/bot"

echo "=== Building Azalea Bot ==="
cd "$BOT_DIR"
cargo build --release 2>&1

echo ""
echo "=== Running Azalea Bot ==="
echo "Connecting to localhost:25565..."
cargo run --release 2>&1
