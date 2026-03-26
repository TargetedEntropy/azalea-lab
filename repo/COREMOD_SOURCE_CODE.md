# NeoForge Coremod - Source Code Reference

This file contains the complete source code for the checkpatch coremod, ready to copy and use.

## File 1: META-INF/coremods.json

**Location in JAR**: `META-INF/coremods.json`

**Location on disk**: `/home/bmerriam/modpack-azalea-lab/repo/server/coremod-jar/META-INF/coremods.json`

```json
{
  "checkPacket": {
    "target": "net.neoforged.neoforge.network.registration.NetworkRegistry",
    "transformer": "checkPacketTransformer"
  }
}
```

**Purpose**: Entry point configuration that tells NeoForge:
- Find the class: `net.neoforged.neoforge.network.registration.NetworkRegistry`
- Use the transformer: `checkPacketTransformer` (JavaScript file without .js extension)

**How to modify**:
- Change `"target"` to the class you want to transform
- Change transformer name to match your JS file name (no extension)

---

## File 2: META-INF/MANIFEST.MF

**Location in JAR**: `META-INF/MANIFEST.MF`

**Location on disk**: `/home/bmerriam/modpack-azalea-lab/repo/server/coremod-jar/META-INF/MANIFEST.MF`

```
Manifest-Version: 1.0
Specification-Title: CheckPacket Coremod
Specification-Version: 1.0.0
Specification-Vendor: Azalea Bot
Implementation-Title: CheckPacket Coremod
Implementation-Version: 1.0.0
Implementation-Vendor: Azalea Bot
```

**Purpose**: Standard JAR manifest metadata

**How to modify**: Update title and version as needed

---

## File 3: checkPacketTransformer.js

**Location in JAR**: `checkPacketTransformer.js` (in JAR root)

**Location on disk**: `/home/bmerriam/modpack-azalea-lab/repo/server/coremod-jar/checkPacketTransformer.js`

```javascript
/**
 * NeoForge Coremod Transformer
 *
 * Transforms NetworkRegistry.checkPacket() to be a no-op (just returns immediately)
 * This prevents the server from validating packet types for connections.
 */

function initializeCoreMod() {
  return {
    'checkPacket': {
      'target': {
        'modid': 'neoforge',
        'classNameObfuscated': 'net/neoforged/neoforge/network/registration/NetworkRegistry',
        'classNameNotObfuscated': 'net/neoforged/neoforge/network/registration/NetworkRegistry',
        'methodNameObfuscated': 'checkPacket',
        'methodNameNotObfuscated': 'checkPacket',
        'methodDescObfuscated': '(Lnet/minecraft/network/protocol/Packet;)V',
        'methodDescNotObfuscated': '(Lnet/minecraft/network/protocol/Packet;)V'
      },
      'transformer': function(classNode, environment) {
        var Opcodes = Java.type('org.objectweb.asm.Opcodes');
        var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');

        console.log('[COREMOD CheckPacket] Transforming class: ' + classNode.name);
        console.log('[COREMOD CheckPacket] Found ' + classNode.methods.length + ' methods');

        var foundMethod = false;

        for (var i = 0; i < classNode.methods.length; i++) {
          var method = classNode.methods[i];

          console.log('[COREMOD CheckPacket] Method ' + i + ': ' + method.name + method.desc);

          if (method.name === 'checkPacket' &&
              method.desc === '(Lnet/minecraft/network/protocol/Packet;)V') {

            console.log('[COREMOD CheckPacket] Found target method! Replacing with no-op.');
            console.log('[COREMOD CheckPacket] Original method has ' + method.instructions.size() + ' instructions');

            // Clear all existing instructions from the method
            method.instructions.clear();

            // Add a single RETURN instruction (void return)
            // RETURN opcode = 177 (0xB1)
            method.instructions.add(new InsnNode(Opcodes.RETURN));

            console.log('[COREMOD CheckPacket] Method replaced with RETURN instruction');

            foundMethod = true;
            break;
          }
        }

        if (!foundMethod) {
          console.log('[COREMOD CheckPacket] WARNING: checkPacket method not found in class!');
          console.log('[COREMOD CheckPacket] Class has these methods:');
          for (var i = 0; i < classNode.methods.length; i++) {
            console.log('[COREMOD CheckPacket]   - ' + classNode.methods[i].name + classNode.methods[i].desc);
          }
        }

        return classNode;
      }
    }
  };
}
```

**Purpose**: JavaScript transformer that modifies bytecode

**Key parts**:
1. `initializeCoreMod()` - Required entry function
2. Returns a map of transformers
3. Each transformer has `target` (which method) and `transformer` (what to do)
4. The `target` specifies:
   - `modid`: Which mod owns this class
   - `classNameObfuscated/NotObfuscated`: Class name in obfuscated/deobfuscated forms
   - `methodNameObfuscated/NotObfuscated`: Method name
   - `methodDescObfuscated/NotObfuscated`: Method signature in bytecode format
5. The `transformer` function receives the class and modifies it

**How to modify**:
1. Change the target class names
2. Change the target method name and descriptor
3. Modify the transformation logic (what to do to the method)

---

## File 4: build-coremod.sh

**Location on disk**: `/home/bmerriam/modpack-azalea-lab/repo/server/build-coremod.sh`

```bash
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
```

**Purpose**: Bash script that creates the JAR file

**How to run**:
```bash
bash /home/bmerriam/modpack-azalea-lab/repo/server/build-coremod.sh
```

**What it does**:
1. Verifies required files exist
2. Runs `jar` command to create JAR
3. Shows final JAR contents

---

## Complete Directory Structure

```
server/
├── build-coremod.sh                    (Build script)
├── checkpatch-coremod-1.0.0.jar        (Built output)
│
└── coremod-jar/                        (Source files)
    ├── checkPacketTransformer.js       (File 3)
    └── META-INF/
        ├── MANIFEST.MF                 (File 2)
        ├── coremods.json               (File 1)
        └── services/                   (Empty directory)
```

---

## Quick Copy-Paste Guide

### Creating a new coremod

1. Create directories:
```bash
mkdir -p my-coremod/META-INF/services
```

2. Create `META-INF/coremods.json`:
```json
{
  "myTransform": {
    "target": "fully.qualified.ClassName",
    "transformer": "myTransformer"
  }
}
```

3. Create `myTransformer.js`:
```javascript
function initializeCoreMod() {
  return {
    'myTransform': {
      'target': {
        'modid': 'neoforge',
        'classNameObfuscated': 'path/to/Class',
        'classNameNotObfuscated': 'path/to/Class',
        'methodNameObfuscated': 'methodName',
        'methodNameNotObfuscated': 'methodName',
        'methodDescObfuscated': '()V',
        'methodDescNotObfuscated': '()V'
      },
      'transformer': function(classNode, environment) {
        for (var i = 0; i < classNode.methods.length; i++) {
          var method = classNode.methods[i];
          if (method.name === 'methodName' && method.desc === '()V') {
            // Transform method here
            break;
          }
        }
        return classNode;
      }
    }
  };
}
```

4. Create `META-INF/MANIFEST.MF`:
```
Manifest-Version: 1.0
```

5. Create `build.sh`:
```bash
#!/bin/bash
cd my-coremod
jar cf ../my-coremod.jar META-INF/ *.js
```

6. Build:
```bash
bash build.sh
```

---

## Method Descriptor Examples

| Java Signature | Descriptor | Explanation |
|---|---|---|
| `void checkPacket(Packet p)` | `(Lnet/minecraft/network/protocol/Packet;)V` | Object param, void return |
| `boolean canProcess()` | `()Z` | No params, boolean return |
| `int getCount()` | `()I` | No params, int return |
| `void setValue(int v)` | `(I)V` | int param, void return |
| `String getName()` | `()Ljava/lang/String;` | No params, String return |
| `void process(List l, String s)` | `(Ljava/util/List;Ljava/lang/String;)V` | Two object params, void return |

---

## Common ASM Operations in JavaScript

### Make a method do nothing (void)
```javascript
var Opcodes = Java.type('org.objectweb.asm.Opcodes');
var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');
method.instructions.clear();
method.instructions.add(new InsnNode(Opcodes.RETURN));
```

### Make a method return false (boolean)
```javascript
method.instructions.clear();
method.instructions.add(new InsnNode(Opcodes.ICONST_0));    // Push 0
method.instructions.add(new InsnNode(Opcodes.IRETURN));     // Return int/boolean
```

### Make a method return true (boolean)
```javascript
method.instructions.clear();
method.instructions.add(new InsnNode(Opcodes.ICONST_1));    // Push 1
method.instructions.add(new InsnNode(Opcodes.IRETURN));     // Return int/boolean
```

### Make a method return null (object)
```javascript
method.instructions.clear();
method.instructions.add(new InsnNode(Opcodes.ACONST_NULL)); // Push null
method.instructions.add(new InsnNode(Opcodes.ARETURN));     // Return object
```

### Make a method return 0 (int)
```javascript
method.instructions.clear();
method.instructions.add(new InsnNode(Opcodes.ICONST_0));    // Push 0
method.instructions.add(new InsnNode(Opcodes.IRETURN));     // Return int
```

---

## Debugging

### Add logging
```javascript
console.log('[COREMOD] Message: ' + value);
```

### List all methods in class
```javascript
console.log('[COREMOD] Methods in ' + classNode.name + ':');
for (var i = 0; i < classNode.methods.length; i++) {
  var m = classNode.methods[i];
  console.log('[COREMOD]   ' + m.name + m.desc);
}
```

### List all instructions in method
```javascript
console.log('[COREMOD] Instructions in ' + method.name + ':');
for (var i = 0; i < method.instructions.size(); i++) {
  var insn = method.instructions.get(i);
  console.log('[COREMOD]   ' + i + ': ' + insn.getClass().getSimpleName());
}
```

---

## Testing

1. Copy JAR to mods/
2. Start server
3. Check logs/latest.log for [COREMOD] messages
4. Verify transformation happened
5. Test that method behaves as expected

---

## Summary

You have 4 files to work with:

1. **coremods.json** - Configuration (tells NeoForge what to transform)
2. **MANIFEST.MF** - JAR metadata (standard)
3. **checkPacketTransformer.js** - JavaScript transformer (does the transformation)
4. **build-coremod.sh** - Build script (creates the JAR)

The key is the JavaScript file, which uses the ASM API to modify bytecode before the class is loaded.
