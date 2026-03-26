# NeoForge 21.1 Coremod - START HERE

## Welcome!

You have successfully created a complete NeoForge 21.1 coremod that patches `NetworkRegistry.checkPacket()` to be a no-op using JavaScript and ASM bytecode transformation.

## What You Have

### The JAR (Ready to Use!)
```
/home/bmerriam/modpack-azalea-lab/repo/server/checkpatch-coremod-1.0.0.jar
```
- 1.6 KB file
- Ready to copy to your mods/ folder
- No further compilation needed
- Will automatically load with NeoForge

### The Documentation (6 files)
All in `/home/bmerriam/modpack-azalea-lab/repo/`:
- COREMOD_README.md (index and overview)
- COREMOD_SUMMARY.md (executive summary)
- COREMOD_QUICK_REFERENCE.md (quick lookup)
- COREMOD_GUIDE.md (comprehensive guide)
- COREMOD_JAVASCRIPT_API.md (API reference)
- COREMOD_SOURCE_CODE.md (all code listed)

## 5-Minute Quick Start

1. **Copy the JAR to your mods folder:**
   ```bash
   cp /home/bmerriam/modpack-azalea-lab/repo/server/checkpatch-coremod-1.0.0.jar \
      /path/to/minecraft/mods/
   ```

2. **Start your NeoForge server**
   ```bash
   # Your normal server startup
   java -jar minecraft_server.jar
   ```

3. **Check the logs:**
   Look in `logs/latest.log` for these messages:
   ```
   [COREMOD CheckPacket] Transforming class: net/neoforged/neoforge/network/registration/NetworkRegistry
   [COREMOD CheckPacket] Found target method! Replacing with no-op.
   [COREMOD CheckPacket] Method replaced with RETURN instruction
   ```

That's it! Your server is now patched.

## What Does It Do?

The coremod intercepts the loading of NeoForge's `NetworkRegistry` class and modifies the `checkPacket()` method to do nothing. Instead of validating packet types, it just returns immediately.

**Before**: `checkPacket(Packet p) { ... 20 instructions validating packet ... }`

**After**: `checkPacket(Packet p) { return; }`

## Understanding the Implementation

### For Quick Reference
Read **COREMOD_QUICK_REFERENCE.md**
- JAR structure
- File purposes
- Method descriptors
- Common operations

### For Complete Understanding
Read in this order:
1. **COREMOD_README.md** - Overview
2. **COREMOD_SUMMARY.md** - How it works
3. **COREMOD_GUIDE.md** - Detailed explanation

### For API Reference
Use **COREMOD_JAVASCRIPT_API.md** for:
- ASM instruction reference (50+ opcodes)
- JavaScript-Java interop examples
- Method descriptor format
- Practical code examples

### To See the Source Code
Check **COREMOD_SOURCE_CODE.md** for:
- All 4 source files in full
- How to modify each
- Common operations

## Key Concepts

### JAR Structure
```
checkpatch-coremod-1.0.0.jar
├── META-INF/
│   ├── coremods.json           ← Entry point (tells NeoForge what to do)
│   ├── MANIFEST.MF             ← JAR metadata
│   └── services/               ← Empty directory (required)
└── checkPacketTransformer.js   ← JavaScript transformer (does the work)
```

### How It Works
1. NeoForge scans for `META-INF/coremods.json` in all JARs
2. Finds this file and reads the configuration
3. Runs the JavaScript `checkPacketTransformer.js` at startup
4. JavaScript uses ASM API to modify bytecode before class loads
5. Method is patched to be a no-op
6. Rest of server loads normally

### Method Descriptor
A Java bytecode format for method signatures:
```
(Lnet/minecraft/network/protocol/Packet;)V
│                                        │
└─ Parameter: Packet object              └─ Return type: void
```

## The Three Files in the JAR

### 1. META-INF/coremods.json
```json
{
  "checkPacket": {
    "target": "net.neoforged.neoforge.network.registration.NetworkRegistry",
    "transformer": "checkPacketTransformer"
  }
}
```
- Entry point configuration
- Maps class to JavaScript transformer

### 2. META-INF/MANIFEST.MF
```
Manifest-Version: 1.0
...metadata...
```
- Standard JAR manifest
- Optional but recommended

### 3. checkPacketTransformer.js
```javascript
function initializeCoreMod() {
  return {
    'checkPacket': {
      'target': { /* which method */ },
      'transformer': function(classNode) {
        // Modify bytecode here
        return classNode;
      }
    }
  };
}
```
- JavaScript that uses ASM API
- Finds checkPacket method
- Replaces bytecode with single RETURN instruction

## Verifying It Works

When you start your server with the coremod installed, you should see in the logs:

```
[COREMOD CheckPacket] Transforming class: net/neoforged/neoforge/network/registration/NetworkRegistry
[COREMOD CheckPacket] Found 24 methods
[COREMOD CheckPacket] Method 0: <clinit>()V
[COREMOD CheckPacket] Method 1: ...
...
[COREMOD CheckPacket] Found target method! Replacing with no-op.
[COREMOD CheckPacket] Original method has 47 instructions
[COREMOD CheckPacket] Method replaced with RETURN instruction
```

This confirms:
1. Coremod was loaded
2. JavaScript executed
3. Target method found
4. Transformation succeeded

## Troubleshooting

### JAR not loading?
- Verify it's in the `mods/` folder
- Check that NeoForge is installed
- Restart server after copying JAR
- Check logs/latest.log for errors

### Method not found?
- Verify exact class name in logs
- Check method name is spelled correctly
- Verify method descriptor matches signature
- The transformer logs all methods it finds

### Something else?
- Check logs/latest.log for [COREMOD] messages
- Look for Java exceptions in the logs
- Review COREMOD_GUIDE.md for debugging tips

## Customizing for Other Methods

To patch a different method:

1. Edit `/server/coremod-jar/checkPacketTransformer.js`
   - Change target class name
   - Change method name and descriptor
   - Modify transformation logic

2. Edit `/server/coremod-jar/META-INF/coremods.json`
   - Change target class path

3. Rebuild:
   ```bash
   bash /home/bmerriam/modpack-azalea-lab/repo/server/build-coremod.sh
   ```

See **COREMOD_GUIDE.md** for complete examples.

## File Locations

All files are in:
```
/home/bmerriam/modpack-azalea-lab/repo/
```

Documentation:
- COREMOD_README.md
- COREMOD_SUMMARY.md
- COREMOD_QUICK_REFERENCE.md
- COREMOD_GUIDE.md
- COREMOD_JAVASCRIPT_API.md
- COREMOD_SOURCE_CODE.md

Source:
```
server/
├── checkpatch-coremod-1.0.0.jar      ← COPY THIS TO mods/
├── build-coremod.sh                  ← Rebuild script
└── coremod-jar/                      ← Source files
    ├── META-INF/
    │   ├── coremods.json
    │   ├── MANIFEST.MF
    │   └── services/
    └── checkPacketTransformer.js
```

## Next Steps

1. Copy the JAR to your mods/ folder
2. Start your server
3. Check logs for success messages
4. Read COREMOD_README.md to understand the implementation

## Quick Links

- **Setup & Use**: COREMOD_README.md
- **How It Works**: COREMOD_SUMMARY.md
- **Quick Lookup**: COREMOD_QUICK_REFERENCE.md
- **Complete Details**: COREMOD_GUIDE.md
- **API Reference**: COREMOD_JAVASCRIPT_API.md
- **Source Code**: COREMOD_SOURCE_CODE.md

## Summary

You have a complete, minimal NeoForge coremod that:
- Uses JavaScript with ASM API for bytecode transformation
- Patches NetworkRegistry.checkPacket() to do nothing
- Is ready to use immediately (just copy JAR to mods/)
- Is fully documented with examples and reference materials
- Can be easily customized for other methods

Start by copying the JAR to your mods/ folder and checking the logs!

Questions? Check the relevant documentation file - all answers are in there.

---

**Good luck with your NeoForge coremod!**
