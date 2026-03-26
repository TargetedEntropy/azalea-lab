#!/usr/bin/env bash
# =============================================================================
# build.sh — Assemble the server-deploy package from modpack zips + patches
#
# Usage:
#   ./build.sh /path/to/DynamicOdyssey-Server-X.Y.Z.zip
#   ./build.sh                    # uses existing pack/ if already extracted
#
# After running:
#   docker compose up -d          # build image & start server
#   ./run_bot.sh                  # connect the bot
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_SERVER="$SCRIPT_DIR/../repo/server"

# --- Handle server zip argument ---
if [ "${1:-}" != "" ]; then
    SERVER_ZIP="$(realpath "$1")"
    if [ ! -f "$SERVER_ZIP" ]; then
        echo "ERROR: File not found: $SERVER_ZIP"
        exit 1
    fi
    echo "==> Extracting server modpack from: $(basename "$SERVER_ZIP")"

    # Clean out old pack contents
    rm -rf "$SCRIPT_DIR/pack"
    mkdir -p "$SCRIPT_DIR/pack"

    # Extract zip into pack/ (flat — no subdirectory wrapper)
    unzip -qo "$SERVER_ZIP" -d "$SCRIPT_DIR/pack"

    echo "    pack/ extracted OK"
else
    if [ ! -d "$SCRIPT_DIR/pack" ] || [ ! -f "$SCRIPT_DIR/pack/neoforge-"*"-installer.jar" ] 2>/dev/null; then
        echo "ERROR: No zip provided and pack/ is empty."
        echo ""
        echo "Usage: $0 /path/to/DynamicOdyssey-Server-X.Y.Z.zip"
        exit 1
    fi
    echo "==> Using existing pack/ directory"
fi

# --- Detect NeoForge version from installer jar ---
INSTALLER_JAR=$(ls "$SCRIPT_DIR/pack"/neoforge-*-installer.jar 2>/dev/null | head -1)
if [ -z "$INSTALLER_JAR" ]; then
    echo "ERROR: No neoforge-*-installer.jar found in pack/"
    exit 1
fi
NEOFORGE_VERSION=$(basename "$INSTALLER_JAR" | sed 's/neoforge-\(.*\)-installer\.jar/\1/')
echo "    NeoForge version: $NEOFORGE_VERSION"

# --- Patches ---
mkdir -p "$SCRIPT_DIR/patches"
cp "$REPO_SERVER/NegotiationPatch.java"          "$SCRIPT_DIR/patches/"
cp "$REPO_SERVER/ConfigInitPatch.java"            "$SCRIPT_DIR/patches/"
cp "$REPO_SERVER/checkpatch-coremod-1.0.0.jar"   "$SCRIPT_DIR/patches/"
echo "    patches/ OK"

# --- Write .env for docker-compose (NeoForge version) ---
cat > "$SCRIPT_DIR/.env" <<EOF
NEOFORGE_VERSION=$NEOFORGE_VERSION
EOF
echo "    .env OK (NEOFORGE_VERSION=$NEOFORGE_VERSION)"

# --- Summary ---
NMOD=$(ls "$SCRIPT_DIR/pack/mods/"*.jar 2>/dev/null | wc -l)
echo ""
echo "==> Done! Package assembled:"
echo "    NeoForge:  $NEOFORGE_VERSION"
echo "    Mods:      $NMOD JARs"
echo "    Pack dirs: $(ls -d "$SCRIPT_DIR/pack"/*/ 2>/dev/null | xargs -I{} basename {} | tr '\n' ' ')"
echo ""
echo "Next steps:"
echo "  docker compose build         # build Docker image"
echo "  docker compose up -d         # start server (port ${MC_PORT:-25566})"
echo "  docker logs -f azalea-mc-server  # tail logs, wait for 'Done'"
echo "  ./run_bot.sh                 # connect the bot"
echo ""
echo "To update the modpack later:"
echo "  ./build.sh /path/to/new-DynamicOdyssey-Server-X.Y.Z.zip"
echo "  docker compose build && docker compose up -d"
