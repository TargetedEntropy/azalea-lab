#!/usr/bin/env bash
# Build the azalea-bridge coremod JAR from coremod-jar-v2/ sources
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/coremod-jar-v2"
OUT="$SCRIPT_DIR/azalea-bridge-2.5.0.jar"

cd "$SRC"
jar cfm "$OUT" META-INF/MANIFEST.MF \
    META-INF/coremods.json \
    META-INF/neoforge.mods.toml \
    azalea_bridge.js

echo "Built: $OUT"
echo "Size: $(du -h "$OUT" | cut -f1)"
