# NeoForge Coremod Quick Reference

## What You Have

Your minimal coremod JAR has been created at:
```
/home/bmerriam/modpack-azalea-lab/repo/server/checkpatch-coremod-1.0.0.jar
```

## Jar Structure

```
checkpatch-coremod-1.0.0.jar
├── META-INF/
│   ├── MANIFEST.MF
│   ├── coremods.json          ← Entry point - tells NeoForge what to transform
│   └── services/              ← Empty but needed by NeoForge
└── checkPacketTransformer.js  ← The JavaScript transformer (in JAR root)
```

## What Each File Does

### META-INF/coremods.json

**Purpose**: Entry point that tells NeoForge:
1. Which class to transform: `net.neoforged.neoforge.network.registration.NetworkRegistry`
2. Which transformer script to use: `checkPacketTransformer.js`

**Format**:
```json
{
  "checkPacket": {                    // Arbitrary name for logging
    "target": "full.class.Name",      // Class to transform
    "transformer": "transformerName"  // JS file (no .js extension)
  }
}
```

### checkPacketTransformer.js

**Purpose**: JavaScript code that uses ASM API to modify bytecode at load time

**Key Function**:
```javascript
function initializeCoreMod() {
  // Return a map of transformers
  return {
    'transformerName': {
      'target': { /* method specification */ },
      'transformer': function(classNode, environment) {
        // Modify classNode's methods
        return classNode;
      }
    }
  };
}
```

## Target Specification

Tells NeoForge exactly which method to transform:

```javascript
'target': {
  'modid': 'neoforge',                    // Which mod this class belongs to
  'classNameObfuscated': 'path/To/Class', // Obfuscated name (production)
  'classNameNotObfuscated': 'path/To/Class', // Deobfuscated name (dev)
  'methodNameObfuscated': 'checkPacket',   // Obfuscated method name
  'methodNameNotObfuscated': 'checkPacket',// Deobfuscated method name
  'methodDescObfuscated': '(Lnet/minecraft/network/protocol/Packet;)V',
  'methodDescNotObfuscated': '(Lnet/minecraft/network/protocol/Packet;)V'
}
```

**Note**: Paths use `/` not `.` for classes in descriptors.

## Method Descriptors

Format: `(paramTypes)returnType`

| Example | Descriptor | Explanation |
|---------|-----------|-------------|
| `void method()` | `()V` | No params, void return |
| `void checkPacket(Packet p)` | `(Lnet/minecraft/network/protocol/Packet;)V` | Object param, void |
| `int getValue()` | `()I` | No params, int return |
| `boolean test(int x, String s)` | `(ILjava/lang/String;)Z` | int + String, boolean |

**Primitive Type Codes**:
- `V` = void
- `I` = int
- `J` = long
- `Z` = boolean
- `F` = float
- `D` = double
- `B` = byte
- `C` = char
- `S` = short

**Object Format**: `L<class/path>;`

## ASM Bytecode Instructions

### For Making a Method a No-Op

**Void method**:
```javascript
var Opcodes = Java.type('org.objectweb.asm.Opcodes');
var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');

method.instructions.clear();
method.instructions.add(new InsnNode(Opcodes.RETURN));
```

**Method returning int**:
```javascript
method.instructions.clear();
method.instructions.add(new InsnNode(Opcodes.ICONST_0));  // Push 0
method.instructions.add(new InsnNode(Opcodes.IRETURN));   // Return int
```

**Method returning object (null)**:
```javascript
method.instructions.clear();
method.instructions.add(new InsnNode(Opcodes.ACONST_NULL)); // Push null
method.instructions.add(new InsnNode(Opcodes.ARETURN));     // Return object
```

### Common Opcodes

| Opcode | Effect | Use For |
|--------|--------|---------|
| `RETURN` | Return void | Void methods |
| `IRETURN` | Return int | int methods |
| `LRETURN` | Return long | long methods |
| `FRETURN` | Return float | float methods |
| `DRETURN` | Return double | double methods |
| `ARETURN` | Return object | Object methods |
| `ICONST_0` | Push 0 | Return 0 from int |
| `ICONST_1` | Push 1 | Return 1 from int |
| `ACONST_NULL` | Push null | Return null from object |
| `NOP` | No operation | Do nothing |

## Full Example: checkPacket No-Op

Your current transformer does exactly this:

```javascript
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
        for (var i = 0; i < classNode.methods.length; i++) {
          var method = classNode.methods[i];

          // Find the checkPacket method
          if (method.name === 'checkPacket' &&
              method.desc === '(Lnet/minecraft/network/protocol/Packet;)V') {

            // Replace with RETURN
            method.instructions.clear();
            var Opcodes = Java.type('org.objectweb.asm.Opcodes');
            var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');
            method.instructions.add(new InsnNode(Opcodes.RETURN));

            break;
          }
        }
        return classNode;
      }
    }
  };
}
```

## How to Use

### 1. Build the JAR

Already done! The file is at:
```
/home/bmerriam/modpack-azalea-lab/repo/server/checkpatch-coremod-1.0.0.jar
```

### 2. Place in Mods Directory

Copy to your Minecraft/NeoForge server:
```bash
cp /home/bmerriam/modpack-azalea-lab/repo/server/checkpatch-coremod-1.0.0.jar /path/to/minecraft/mods/
```

### 3. Run Server

The coremod will automatically load before the game starts (NeoForge looks for coremods.json in all JARs).

### 4. Verify in Logs

Check your server logs for:
```
[COREMOD CheckPacket] Transforming class: net/neoforged/neoforge/network/registration/NetworkRegistry
[COREMOD CheckPacket] Found target method! Replacing with no-op.
```

## How to Modify for Other Methods

To transform a different method:

1. **Find the method signature**:
   - Class: `net.example.MyClass` → `net/example/MyClass`
   - Method name: `myMethod`
   - Params/return: `(I)V` (int parameter, void return)

2. **Update coremods.json**:
   ```json
   {
     "myTransform": {
       "target": "net.example.MyClass",
       "transformer": "myTransformer"
     }
   }
   ```

3. **Create/update transformer JS**:
   ```javascript
   function initializeCoreMod() {
     return {
       'myTransform': {
         'target': {
           'modid': 'modname',
           'classNameObfuscated': 'net/example/MyClass',
           'classNameNotObfuscated': 'net/example/MyClass',
           'methodNameObfuscated': 'myMethod',
           'methodNameNotObfuscated': 'myMethod',
           'methodDescObfuscated': '(I)V',
           'methodDescNotObfuscated': '(I)V'
         },
         'transformer': function(classNode, environment) {
           // Find and modify method
           for (var i = 0; i < classNode.methods.length; i++) {
             var method = classNode.methods[i];
             if (method.name === 'myMethod' && method.desc === '(I)V') {
               // Make changes here
               break;
             }
           }
           return classNode;
         }
       }
     };
   }
   ```

4. **Rebuild JAR**:
   ```bash
   /home/bmerriam/modpack-azalea-lab/repo/server/build-coremod.sh
   ```

## Debugging Tips

### 1. Add Console Logging

```javascript
console.log('[COREMOD] Class name: ' + classNode.name);
console.log('[COREMOD] Methods found: ' + classNode.methods.length);
for (var i = 0; i < classNode.methods.length; i++) {
  console.log('[COREMOD]   - ' + classNode.methods[i].name +
              classNode.methods[i].desc);
}
```

Logs appear in:
- Server: `logs/latest.log`
- Client: `.minecraft/logs/latest.log`

### 2. Verify JAR Contents

```bash
jar tf /path/to/coremod.jar
```

Must include:
- `META-INF/coremods.json`
- `META-INF/MANIFEST.MF`
- `META-INF/services/` (directory, can be empty)
- Your transformer JS file

### 3. Method Not Found?

Your transformer logs all methods found. Check for:
- Exact method name match
- Exact descriptor match
- Class actually gets loaded

### 4. Syntax Errors in JS?

JavaScript errors appear in logs with Java exception stack traces.

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| Transformer JS | `checkPacketTransformer.js` | Main transformation logic |
| coremods.json | `META-INF/coremods.json` | Entry point config |
| MANIFEST.MF | `META-INF/MANIFEST.MF` | JAR metadata |
| Build script | `/server/build-coremod.sh` | Creates the JAR |
| Built JAR | `/server/checkpatch-coremod-1.0.0.jar` | Final output |

## Related Documentation

- **COREMOD_GUIDE.md** - Comprehensive NeoForge coremod documentation
- **NEOFORGE_21_1_SUMMARY.md** - NeoForge 21.1 network negotiation
- **NEOFORGE_IMPLEMENTATION.md** - Implementation examples

## Tested With

- NeoForge 1.21.x
- Java 17+
- ASM 9.x (included with NeoForge)
