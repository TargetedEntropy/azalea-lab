#!/bin/bash
# Build script for the checkpatch coremod JAR
# Creates a minimal NeoForge coremod that makes NetworkRegistry.checkPacket a no-op

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COREMOD_DIR="$SCRIPT_DIR/coremod-jar"
OUTPUT_JAR="$SCRIPT_DIR/checkpatch-coremod-1.0.0.jar"

echo "Building CheckPacket Coremod..."
echo "Source: $COREMOD_DIR"
echo "Output: $OUTPUT_JAR"

# Change to coremod directory
cd "$COREMOD_DIR"

# Verify required files exist
if [ ! -f "META-INF/coremods.json" ]; then
  echo "ERROR: META-INF/coremods.json not found!"
  exit 1
fi

if [ ! -f "checkPacketTransformer.js" ]; then
  echo "ERROR: checkPacketTransformer.js not found!"
  exit 1
fi

# Create JAR file
# jar command: cf = create, f = file
# We need to include all files relative to the directory
jar cf "$OUTPUT_JAR" META-INF/ checkPacketTransformer.js

echo "✓ JAR created successfully: $OUTPUT_JAR"
echo ""
echo "JAR Contents:"
jar tf "$OUTPUT_JAR"
echo ""
echo "To use this coremod:"
echo "1. Copy $OUTPUT_JAR to your mods/ directory"
echo "2. Ensure it loads BEFORE Minecraft initializes"
echo "3. Check logs/latest.log for [COREMOD CheckPacket] messages"
