# NeoForge 21.1 Coremod Creation Guide

## Overview

A NeoForge coremod is a JAR file that transforms Java bytecode at Minecraft startup, before classes are loaded into memory. This allows you to modify NeoForge or mod classes without source code modifications.

## Jar Structure

A minimal coremod JAR requires:

```
coremod-jar/
├── META-INF/
│   ├── MANIFEST.MF              (optional but recommended)
│   ├── coremods.json            (REQUIRED - entry point)
│   ├── neoforge.mods.toml       (REQUIRED if loading as a mod)
│   └── services/
│       └── net.neoforged.fml.extension.IModLanguageProvider  (optional)
├── net/
│   └── your/
│       └── package/
│           └── transformer.js    (JavaScript transformer script)
└── (compiled .class files if using Java, though JS is preferred)
```

## Required Files

### 1. META-INF/coremods.json

This is the entry point that tells NeoForge how to load your coremod transformers.

**Location**: `META-INF/coremods.json`

**Format**:
```json
{
  "checkPacket": {
    "target": "net.neoforged.neoforge.network.registration.NetworkRegistry",
    "transformer": "net.your.package.CheckPacketTransformer"
  }
}
```

**Explanation**:
- `"checkPacket"`: Arbitrary name for this transformer (for logging)
- `"target"`: Fully qualified class name to transform
- `"transformer"`: JavaScript or class file that performs the transformation
  - If using a `.js` file: Use the path relative to JAR root (no leading `/`)
  - If using compiled Java: Use fully qualified class name

### 2. META-INF/neoforge.mods.toml (If needed)

Only required if you want NeoForge to recognize this as a mod. For a pure coremod, this can be minimal:

```toml
modLoader="javafxmod"
loaderVersion="[1,)"
license="MIT"

[[mods]]
modId="checknoop"
version="1.0.0"
displayName="Check No-Op Coremod"
logoFile="assets/checknoop/icon.png"
```

### 3. Transformer JavaScript

Create a JavaScript file that uses ASM-like API to modify bytecode.

**Location**: `net/your/package/CheckPacketTransformer.js`

```javascript
var ASMAPI = Java.type('net.minecraftforge.coremod.api.ASMAPI');
var Opcodes = Java.type('org.objectweb.asm.Opcodes');
var MethodVisitor = Java.type('org.objectweb.asm.MethodVisitor');

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
          if (method.name === 'checkPacket' && method.desc === '(Lnet/minecraft/network/protocol/Packet;)V') {
            console.log('[COREMOD] Found checkPacket method, making it no-op');
            replaceMethodWithReturn(method);
          }
        }
        return classNode;
      }
    }
  };
}

function replaceMethodWithReturn(method) {
  // Clear all existing instructions
  method.instructions.clear();

  // Add RETURN instruction (for void method)
  method.instructions.add(
    ASMAPI.getInsnNode(Opcodes.RETURN)
  );
}

function makeInitializer() {
  return initializeCoreMod();
}
```

## Deep Dive: JavaScript Transformer API

### CoreMod Initialization

The JavaScript file MUST export an `initializeCoreMod()` function that returns a transformer configuration object.

**Basic Structure**:
```javascript
function initializeCoreMod() {
  return {
    'transformerName': {
      'target': { /* target specification */ },
      'transformer': function(classNode, environment) {
        // Modify classNode
        return classNode;
      }
    }
  };
}
```

### Target Specification

The `target` object specifies which method to transform:

```javascript
'target': {
  'modid': 'neoforge',  // Usually 'neoforge', 'minecraft', or mod ID
  'classNameObfuscated': 'net/neoforged/neoforge/network/registration/NetworkRegistry',
  'classNameNotObfuscated': 'net/neoforged/neoforge/network/registration/NetworkRegistry',
  'methodNameObfuscated': 'checkPacket',
  'methodNameNotObfuscated': 'checkPacket',
  'methodDescObfuscated': '(Lnet/minecraft/network/protocol/Packet;)V',
  'methodDescNotObfuscated': '(Lnet/minecraft/network/protocol/Packet;)V'
}
```

**Note**: In NeoForge (non-obfuscated dev environment), "Obfuscated" and "NotObfuscated" are usually the same. In production (obfuscated), these can differ.

### Method Descriptor Format

Method descriptors follow Java bytecode conventions:

- `(paramType1paramType2...)returnType`
- `V` = void
- `L<className>;` = object type
- `I` = int, `J` = long, `Z` = boolean, etc.

**Examples**:
- `checkPacket(Packet)V` → `(Lnet/minecraft/network/protocol/Packet;)V`
- `getX()I` → `()I`
- `setValue(I)V` → `(I)V`

### ASM Node Types

Common classes you'll use:

```javascript
var ASMAPI = Java.type('net.minecraftforge.coremod.api.ASMAPI');
var Opcodes = Java.type('org.objectweb.asm.Opcodes');
var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');
var InsnList = Java.type('org.objectweb.asm.tree.InsnList');
var VarInsnNode = Java.type('org.objectweb.asm.tree.VarInsnNode');
var MethodInsnNode = Java.type('org.objectweb.asm.tree.MethodInsnNode');
var LdcInsnNode = Java.type('org.objectweb.asm.tree.LdcInsnNode');
```

### Method Bytecode Structure

A method has:

```javascript
method.name          // String: "checkPacket"
method.desc          // String: "(Lnet/minecraft/network/protocol/Packet;)V"
method.access        // int: access modifiers (PUBLIC, STATIC, etc.)
method.instructions  // InsnList: bytecode instructions
method.exceptions    // List: thrown exceptions
method.localVariables // List: variable names and scopes
```

### Making a Method a No-Op (Return Immediately)

For a void method:

```javascript
function replaceMethodWithReturn(method) {
  method.instructions.clear();
  method.instructions.add(new InsnNode(Opcodes.RETURN));
}
```

For a method that returns an object, int, etc., you need to push the return value first:

```javascript
// Method returns int
var instructions = method.instructions;
instructions.clear();
instructions.add(new InsnNode(Opcodes.ICONST_0));  // Push 0
instructions.add(new InsnNode(Opcodes.IRETURN));    // Return int
```

### Common Opcodes

| Opcode | Java | Description |
|--------|------|-------------|
| `RETURN` | `return;` | Return void |
| `IRETURN` | `return (int);` | Return int |
| `LRETURN` | `return (long);` | Return long |
| `FRETURN` | `return (float);` | Return float |
| `DRETURN` | `return (double);` | Return double |
| `ARETURN` | `return (object);` | Return object reference |
| `ICONST_0` | `0` | Push int 0 |
| `ICONST_1` | `1` | Push int 1 |
| `NOP` | `;` | No operation |
| `ALOAD_0` | `this` | Load local var 0 |
| `ASTORE_1` | `var = ...` | Store to local var 1 |

## Complete Example: checkPacket No-Op Coremod

### File: `META-INF/coremods.json`

```json
{
  "checkPacket": {
    "target": "net.neoforged.neoforge.network.registration.NetworkRegistry",
    "transformer": "checkPacketTransformer"
  }
}
```

### File: `checkPacketTransformer.js`

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
        var foundMethod = false;

        for (var i = 0; i < classNode.methods.length; i++) {
          var method = classNode.methods[i];

          if (method.name === 'checkPacket' &&
              method.desc === '(Lnet/minecraft/network/protocol/Packet;)V') {

            console.log('[COREMOD] Transforming checkPacket to no-op');

            // Clear all instructions
            method.instructions.clear();

            // Add single RETURN instruction
            var Opcodes = Java.type('org.objectweb.asm.Opcodes');
            var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');
            method.instructions.add(new InsnNode(Opcodes.RETURN));

            foundMethod = true;
            break;
          }
        }

        if (!foundMethod) {
          console.log('[COREMOD] WARNING: checkPacket method not found!');
        }

        return classNode;
      }
    }
  };
}
```

## Building the Jar

### Using Gradle

If you have a Gradle build:

```gradle
jar {
  archiveFileName = 'checkpatch-coremod-1.0.0.jar'

  from('src/main/resources') {
    include 'META-INF/**'
    include '**/*.js'
  }
}
```

### Manual Assembly

```bash
# Create directory structure
mkdir -p META-INF/services
mkdir -p net/your/package

# Create coremods.json
cat > META-INF/coremods.json << 'EOF'
{
  "checkPacket": {
    "target": "net.neoforged.neoforge.network.registration.NetworkRegistry",
    "transformer": "checkPacketTransformer"
  }
}
EOF

# Create transformer script
cat > checkPacketTransformer.js << 'EOF'
function initializeCoreMod() { /* ... */ }
EOF

# Create JAR
jar cf checkpatch-coremod-1.0.0.jar META-INF/ checkPacketTransformer.js
```

## Loading the Coremod

### In Development

Place the JAR in:
- `run/mods/` (if using standard Forge setup)
- Or specify in your launcher's classpath BEFORE game starts

### On a Server

Place the JAR in:
- `mods/` directory (NeoForge looks here)
- Or add to classpath before launching

**CRITICAL**: Coremods MUST be loaded BEFORE Minecraft initializes, so they must be in the classpath or mods folder.

## Debugging

Add console logging to your JavaScript:

```javascript
console.log('[COREMOD] Checking class: ' + classNode.name);
console.log('[COREMOD] Found ' + classNode.methods.length + ' methods');
```

Check the latest logs in:
- `.minecraft/logs/latest.log`
- `logs/latest.log`

Search for `[COREMOD]` entries to verify your transformer ran.

## Alternative: Injecting Code Instead of Removing

Instead of making a method no-op, you can inject instructions:

```javascript
function injectLoggingCode(method) {
  var Opcodes = Java.type('org.objectweb.asm.Opcodes');
  var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');
  var FieldInsnNode = Java.type('org.objectweb.asm.tree.FieldInsnNode');
  var MethodInsnNode = Java.type('org.objectweb.asm.tree.MethodInsnNode');
  var LdcInsnNode = Java.type('org.objectweb.asm.tree.LdcInsnNode');
  var VarInsnNode = Java.type('org.objectweb.asm.tree.VarInsnNode');

  var instructions = method.instructions;

  // Insert at beginning: System.out.println("checkPacket called");
  var insertList = new (Java.type('org.objectweb.asm.tree.InsnList'))();

  // System.out
  insertList.add(new FieldInsnNode(Opcodes.GETSTATIC,
    'java/lang/System', 'out', 'Ljava/io/PrintStream;'));

  // "checkPacket called"
  insertList.add(new LdcInsnNode('checkPacket called'));

  // println()
  insertList.add(new MethodInsnNode(Opcodes.INVOKEVIRTUAL,
    'java/io/PrintStream', 'println', '(Ljava/lang/String;)V', false));

  // Insert at the start
  if (instructions.size() > 0) {
    instructions.insertBefore(instructions.get(0), insertList);
  } else {
    instructions.insert(insertList);
  }
}
```

## Testing

1. Create the coremod JAR
2. Place in mods folder
3. Start the game/server with debug logging enabled
4. Search logs for your transformer output
5. Verify the behavior (in this case, checkPacket does nothing)

## Common Issues

| Problem | Solution |
|---------|----------|
| Coremod not loading | Check coremods.json is in META-INF/ |
| Method not found | Verify exact method name and descriptor |
| Transformation fails | Check JavaScript syntax, Java exceptions in logs |
| Changes have no effect | Ensure coremod JAR is in classpath BEFORE launch |
| Obfuscation issues | Use both Obfuscated and NotObfuscated names |

## Resources

- NeoForge Coremod Docs: https://docs.neoforged.net/
- ASM API: https://asm.ow2.io/
- Method Descriptor Format: https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-4.html#jvms-4.3.3
