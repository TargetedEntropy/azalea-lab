# NeoForge Coremod - Complete Implementation

## Overview

This directory contains everything you need to understand, build, and use a NeoForge coremod that transforms classes at load time via JavaScript and the ASM bytecode manipulation library.

**Current Implementation**: A minimal coremod that transforms `net.neoforged.neoforge.network.registration.NetworkRegistry.checkPacket()` to be a no-op (void return).

## Quick Start (30 seconds)

1. **Get the built JAR**:
   ```bash
   /home/bmerriam/modpack-azalea-lab/repo/server/checkpatch-coremod-1.0.0.jar
   ```

2. **Copy to your server**:
   ```bash
   cp server/checkpatch-coremod-1.0.0.jar /path/to/minecraft/mods/
   ```

3. **Start server and check logs**:
   ```
   logs/latest.log should contain:
   [COREMOD CheckPacket] Transforming class...
   [COREMOD CheckPacket] Found target method!
   ```

## Documentation

Read these in order:

### 1. START HERE: COREMOD_SUMMARY.md
**What to read**: Overview of what's been created
- What the coremod does
- Files provided
- How to use it
- Key concepts
- Success indicators

### 2. THEN: COREMOD_QUICK_REFERENCE.md
**What to read**: Quick reference while working
- JAR structure
- File purposes
- Method descriptors
- Common ASM instructions
- How to modify for other methods

### 3. REFERENCE: COREMOD_GUIDE.md
**What to read**: Comprehensive documentation
- JAR structure details
- Required files explained
- JavaScript API overview
- Complete working examples
- Debugging tips
- Manual assembly instructions

### 4. DETAILED: COREMOD_JAVASCRIPT_API.md
**What to read**: In-depth API reference
- JavaScript entry point
- Transformer specification
- ASM classes in JavaScript
- Method node structure
- Instruction types
- Complete opcodes reference
- Practical code examples
- Type descriptors

## File Structure

```
/home/bmerriam/modpack-azalea-lab/repo/
│
├── Documentation Files:
│   ├── COREMOD_README.md              ← You are here
│   ├── COREMOD_SUMMARY.md             ← Start here
│   ├── COREMOD_QUICK_REFERENCE.md     ← Quick lookup
│   ├── COREMOD_GUIDE.md               ← Comprehensive guide
│   └── COREMOD_JAVASCRIPT_API.md      ← API reference
│
└── server/
    ├── checkpatch-coremod-1.0.0.jar   ← BUILT JAR (ready to use!)
    │
    ├── build-coremod.sh               ← Build script
    │
    └── coremod-jar/                   ← Source files
        ├── META-INF/
        │   ├── coremods.json          ← Entry point config
        │   ├── MANIFEST.MF            ← JAR metadata
        │   └── services/              ← Empty (required by NeoForge)
        │
        └── checkPacketTransformer.js  ← JavaScript transformer
```

## What's Included

### Built Artifact
- **checkpatch-coremod-1.0.0.jar** (1.6K)
  - Ready to drop into mods/ folder
  - No additional compilation needed
  - Includes all required META-INF files

### Source Files
- **checkPacketTransformer.js**
  - JavaScript code using ASM API
  - Finds and patches checkPacket method
  - Includes detailed logging

- **META-INF/coremods.json**
  - Entry point configuration
  - Maps class to transformer
  - Specifies method to transform

- **META-INF/MANIFEST.MF**
  - Standard JAR manifest
  - Optional but recommended

### Build System
- **build-coremod.sh**
  - Creates JAR from source files
  - Verifies all files present
  - Shows final contents

### Documentation
- 4 comprehensive markdown files
- Covers beginner to advanced topics
- Includes code examples throughout
- References to official specs

## How Coremods Work

### Load-Time Transformation

```
NeoForge Server Startup
    ↓
Scan for JARs with META-INF/coremods.json
    ↓
For each transformer listed:
    ↓
Load class bytecode from JAR
    ↓
Run JavaScript transformer function
    ↓
JavaScript uses ASM API to modify bytecode
    ↓
Class is loaded with modifications
    ↓
Rest of server starts normally
```

### This Coremod's Transformation

```
Original checkPacket method:
    [~20 bytecode instructions]
    [various packet validation logic]

After transformation:
    [RETURN]
    (exits immediately, does nothing)
```

## Method Signature

The method being transformed:

```java
public void checkPacket(Packet<?> packet) {
    // Original code would validate packet here
    // After coremod: does nothing
}
```

**Bytecode Descriptor**: `(Lnet/minecraft/network/protocol/Packet;)V`

## Key Technologies

### NeoForge Coremod System
- Scans for `META-INF/coremods.json` in classpath
- Loads JavaScript transformers at startup
- Provides ASM API through Java interop

### JavaScript-Java Interop
```javascript
var Java = require('java');
var Opcodes = Java.type('org.objectweb.asm.Opcodes');
var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');
```

### ASM (Abstract Syntax Tree)
- Java bytecode manipulation library
- Tree-based representation of classes
- InsnList (instruction list) for method bytecode

### Method Descriptors
- Java bytecode format: `(params)return`
- Example: `(Lnet/minecraft/network/protocol/Packet;)V`
- Used to uniquely identify methods

## Using the Coremod

### Installation
```bash
# Copy JAR to mods folder
cp /path/to/checkpatch-coremod-1.0.0.jar /minecraft/server/mods/

# Start server
./start.sh  # or however you start your server
```

### Verification
Check `logs/latest.log` for:
```
[COREMOD CheckPacket] Transforming class: net/neoforged/neoforge/network/registration/NetworkRegistry
[COREMOD CheckPacket] Found target method! Replacing with no-op.
[COREMOD CheckPacket] Method replaced with RETURN instruction
```

### Troubleshooting
- **JAR not loading**: Ensure it's in mods/ folder, restart server
- **Method not found**: Check class name and method descriptor
- **Transformation fails**: Check logs for JavaScript errors

## Customizing the Coremod

To transform a different method:

1. **Edit source files**:
   ```bash
   cd /home/bmerriam/modpack-azalea-lab/repo/server/coremod-jar
   ```

2. **Update checkPacketTransformer.js**:
   - Change target class name
   - Change method name and descriptor
   - Modify transformation logic as needed

3. **Update META-INF/coremods.json**:
   - Change target class path

4. **Rebuild**:
   ```bash
   /home/bmerriam/modpack-azalea-lab/repo/server/build-coremod.sh
   ```

5. **Test**:
   - Copy JAR to mods/ and restart

## Examples

### Make a Method Return False

Instead of:
```javascript
method.instructions.add(new InsnNode(Opcodes.RETURN));
```

Use:
```javascript
// ICONST_0 = push 0 (false)
// IRETURN = return int (or boolean)
method.instructions.clear();
method.instructions.add(new InsnNode(Opcodes.ICONST_0));
method.instructions.add(new InsnNode(Opcodes.IRETURN));
```

### Inject Logging

```javascript
var insns = new InsnList();
insns.add(new FieldInsnNode(Opcodes.GETSTATIC,
  'java/lang/System', 'out', 'Ljava/io/PrintStream;'));
insns.add(new LdcInsnNode('Method called!'));
insns.add(new MethodInsnNode(Opcodes.INVOKEVIRTUAL,
  'java/io/PrintStream', 'println', '(Ljava/lang/String;)V', false));
method.instructions.insertBefore(method.instructions.get(0), insns);
```

### Find and Replace Method

```javascript
for (var i = 0; i < classNode.methods.length; i++) {
  var method = classNode.methods[i];
  if (method.name === 'targetMethod' && method.desc === '(I)V') {
    // Transform this method
    break;
  }
}
```

## Common Opcodes

| Opcode | Purpose | Use |
|--------|---------|-----|
| `RETURN` | Return void | Exit void methods |
| `IRETURN` | Return int | Return from int/boolean methods |
| `ARETURN` | Return object | Return from object methods |
| `ICONST_0` | Push 0 | Return 0/false |
| `ICONST_1` | Push 1 | Return 1/true |
| `ACONST_NULL` | Push null | Return null |
| `NOP` | No-op | Placeholder |

See COREMOD_JAVASCRIPT_API.md for complete reference.

## Testing Checklist

- [ ] JAR file created successfully
- [ ] JAR contains META-INF/coremods.json
- [ ] JAR contains checkPacketTransformer.js
- [ ] Copied to mods/ folder
- [ ] Server started
- [ ] Logs show [COREMOD] messages
- [ ] Transformation completed successfully
- [ ] Method now behaves differently (no-op in this case)

## References

- [NeoForge Documentation](https://docs.neoforged.net/)
- [ASM Manual](https://asm.ow2.io/asm4-guide.pdf)
- [JVM Specification](https://docs.oracle.com/javase/specs/jvms/se17/html/)
- [Method Descriptors](https://docs.oracle.com/javase/specs/jvms/se17/html/jvms-4.html#jvms-4.3.3)

## Source Code References

The coremod targets:
- Class: `net.neoforged.neoforge.network.registration.NetworkRegistry`
- Method: `checkPacket(Packet<?> packet): void`
- Location: NeoForge 1.21.x source code

## Files Summary

| File | Size | Purpose |
|------|------|---------|
| COREMOD_README.md | This file | Index and overview |
| COREMOD_SUMMARY.md | ~5KB | Executive summary |
| COREMOD_QUICK_REFERENCE.md | ~8KB | Quick lookup guide |
| COREMOD_GUIDE.md | ~12KB | Comprehensive guide |
| COREMOD_JAVASCRIPT_API.md | ~15KB | Detailed API reference |
| server/checkpatch-coremod-1.0.0.jar | 1.6KB | **Ready to use!** |
| server/build-coremod.sh | ~1KB | Build script |
| server/coremod-jar/META-INF/coremods.json | ~0.2KB | Config |
| server/coremod-jar/checkPacketTransformer.js | ~2KB | Transformer |

## Getting Started Now

1. **Read**: Open COREMOD_SUMMARY.md
2. **Copy**: Get checkpatch-coremod-1.0.0.jar into your mods/
3. **Test**: Start server and check logs
4. **Learn**: Read other docs as needed
5. **Modify**: Use COREMOD_GUIDE.md to customize

## Support

If something doesn't work:

1. Check `logs/latest.log` for [COREMOD] messages
2. Verify JAR is in mods/ folder
3. Ensure NeoForge is installed
4. Read error messages in logs
5. Check COREMOD_JAVASCRIPT_API.md for syntax help
6. Compare to the provided example

## Version Info

- **NeoForge**: 1.21.x
- **Java**: 17+
- **ASM**: 9.x (included with NeoForge)
- **JavaScript Engine**: Nashorn (Java 11+)

## License

These files document standard NeoForge coremod techniques. Use freely for your projects.

---

**Next Step**: Read COREMOD_SUMMARY.md to understand what's been created.
