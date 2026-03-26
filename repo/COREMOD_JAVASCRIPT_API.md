# NeoForge Coremod JavaScript API Reference

## Overview

NeoForge coremods use a JavaScript-ASM bridge to transform Java bytecode. The JavaScript runs at server startup, before classes are loaded, and can modify bytecode using the ASM library.

## Entry Point: initializeCoreMod()

Every coremod transformer JavaScript file MUST export a function called `initializeCoreMod()`:

```javascript
function initializeCoreMod() {
  return {
    // Return a map of transformer definitions
    'transformerName': { /* transformer spec */ },
    'anotherTransformer': { /* another spec */ }
  };
}
```

This function is called by NeoForge and should return a JavaScript object mapping transformer names to transformer specifications.

## Transformer Specification

Each entry in the returned object defines one transformation:

```javascript
'transformerName': {
  'target': {
    // Specifies which method to transform
  },
  'transformer': function(classNode, environment) {
    // Function that performs the transformation
    return classNode;
  }
}
```

### Target Specification

The `target` object identifies the exact method to transform:

```javascript
'target': {
  'modid': 'modname',                    // Mod ID (usually 'neoforge', 'minecraft')
  'classNameObfuscated': 'path/To/Class',      // Obfuscated class name (production)
  'classNameNotObfuscated': 'path/To/Class',   // Deobfuscated class name (dev)
  'methodNameObfuscated': 'methodName',        // Obfuscated method name
  'methodNameNotObfuscated': 'methodName',     // Deobfuscated method name
  'methodDescObfuscated': '(P1P2...)R',        // Obfuscated method descriptor
  'methodDescNotObfuscated': '(P1P2...)R'      // Deobfuscated method descriptor
}
```

**Key Points**:
- **classNameObfuscated** vs **classNameNotObfuscated**: Different names in production (obfuscated) vs dev. Usually same in dev.
- **methodDesc format**: `(paramTypes)returnType` (Java bytecode format)
- **Class paths use `/` not `.`**: `net/minecraft/server/Server`, not `net.minecraft.server.Server`

### Transformer Function

The transformer function receives:
1. **classNode**: The ASM ClassNode representing the entire class
2. **environment**: Environment information (rarely used)

```javascript
'transformer': function(classNode, environment) {
  // classNode.name - String, the class name
  // classNode.methods - List<MethodNode>
  // classNode.fields - List<FieldNode>
  // classNode.interfaces - List<String>

  return classNode;  // MUST return the modified classNode
}
```

## ASM Classes Available in JavaScript

You access ASM classes through Java interop:

```javascript
var ASMAPI = Java.type('net.minecraftforge.coremod.api.ASMAPI');
var Opcodes = Java.type('org.objectweb.asm.Opcodes');
var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');
var InsnList = Java.type('org.objectweb.asm.tree.InsnList');
var MethodNode = Java.type('org.objectweb.asm.tree.MethodNode');
var FieldNode = Java.type('org.objectweb.asm.tree.FieldNode');
var ClassNode = Java.type('org.objectweb.asm.tree.ClassNode');
```

## Method Node Structure

When you get a method from `classNode.methods`, it has this structure:

```javascript
var method = classNode.methods[0];

method.name              // String: method name
method.desc              // String: method descriptor "(params)return"
method.access            // int: access modifiers (Opcodes.PUBLIC, etc)
method.signature         // String: generic signature (null if none)
method.exceptions        // List<String>: thrown exceptions
method.annotations       // List<AnnotationNode>
method.instructions      // InsnList: the bytecode
method.localVariables    // List<LocalVariableNode>
method.tryCatchBlocks    // List<TryCatchBlockNode>
method.maxStack          // int: max stack size
method.maxLocals         // int: max local variables
```

### Accessing Instructions

The `method.instructions` is an InsnList (doubly-linked list of instructions):

```javascript
// Get all instructions
for (var i = 0; i < method.instructions.size(); i++) {
  var insn = method.instructions.get(i);
  console.log('Instruction ' + i + ': ' + insn);
}

// Clear instructions
method.instructions.clear();

// Add instruction at end
method.instructions.add(new InsnNode(Opcodes.RETURN));

// Insert instruction before specific position
method.instructions.insertBefore(method.instructions.get(0), newInsn);

// Remove instruction
method.instructions.remove(insn);
```

## Instruction Types

Different instruction types in ASM:

### InsnNode - Simple Instructions

Single-byte instructions with no operands:

```javascript
var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');

// RETURN (void)
method.instructions.add(new InsnNode(Opcodes.RETURN));

// NOP (no operation)
method.instructions.add(new InsnNode(Opcodes.NOP));

// ICONST_0 (push int 0)
method.instructions.add(new InsnNode(Opcodes.ICONST_0));
```

### VarInsnNode - Variable Instructions

Instructions that access local variables:

```javascript
var VarInsnNode = Java.type('org.objectweb.asm.tree.VarInsnNode');

// ALOAD 0 (load local variable 0 - usually 'this')
method.instructions.add(new VarInsnNode(Opcodes.ALOAD, 0));

// ISTORE 1 (store to local variable 1)
method.instructions.add(new VarInsnNode(Opcodes.ISTORE, 1));
```

### MethodInsnNode - Method Call Instructions

Instructions that call methods:

```javascript
var MethodInsnNode = Java.type('org.objectweb.asm.tree.MethodInsnNode');

// System.out.println("message")
method.instructions.add(new FieldInsnNode(
  Opcodes.GETSTATIC,
  'java/lang/System',
  'out',
  'Ljava/io/PrintStream;'
));

method.instructions.add(new LdcInsnNode('message'));

method.instructions.add(new MethodInsnNode(
  Opcodes.INVOKEVIRTUAL,
  'java/io/PrintStream',
  'println',
  '(Ljava/lang/String;)V',
  false  // not an interface method
));
```

### LdcInsnNode - Load Constant

Load a constant value onto the stack:

```javascript
var LdcInsnNode = Java.type('org.objectweb.asm.tree.LdcInsnNode');

// Push a string constant
method.instructions.add(new LdcInsnNode('my string'));

// Push an integer constant (if not small value)
method.instructions.add(new LdcInsnNode(12345));

// Push a long constant
method.instructions.add(new LdcInsnNode(Java.type('java.lang.Long').valueOf(999999)));
```

### FieldInsnNode - Field Access

Access fields (static or instance):

```javascript
var FieldInsnNode = Java.type('org.objectweb.asm.tree.FieldInsnNode');

// System.out
method.instructions.add(new FieldInsnNode(
  Opcodes.GETSTATIC,
  'java/lang/System',
  'out',
  'Ljava/io/PrintStream;'
));

// this.myField
method.instructions.add(new VarInsnNode(Opcodes.ALOAD, 0));
method.instructions.add(new FieldInsnNode(
  Opcodes.GETFIELD,
  'my/package/MyClass',
  'myField',
  'I'  // field descriptor
));
```

## Opcodes Reference

### Stack Operations

| Opcode | Stack Effect | Use |
|--------|--------------|-----|
| `NOP` | (none) | Do nothing |
| `POP` | ...v → ... | Remove top value |
| `POP2` | ...v1 v2 → ... | Remove top 2 values |
| `DUP` | ...v → ...v v | Duplicate top |
| `DUP2` | ...v1 v2 → ...v1 v2 v1 v2 | Duplicate top 2 |
| `SWAP` | ...v1 v2 → ...v2 v1 | Swap top 2 |

### Arithmetic

| Opcode | Stack Effect | Type |
|--------|--------------|------|
| `IADD`, `LADD`, `FADD`, `DADD` | ...a b → ...result | Add |
| `ISUB`, `LSUB`, `FSUB`, `DSUB` | ...a b → ...result | Subtract |
| `IMUL`, `LMUL`, `FMUL`, `DMUL` | ...a b → ...result | Multiply |
| `IDIV`, `LDIV`, `FDIV`, `DDIV` | ...a b → ...result | Divide |

### Constants

| Opcode | Effect | Value |
|--------|--------|-------|
| `ACONST_NULL` | → null | null |
| `ICONST_M1` | → -1 | -1 |
| `ICONST_0` | → 0 | 0 |
| `ICONST_1` | → 1 | 1 |
| `ICONST_2` | → 2 | 2 |
| `ICONST_3` | → 3 | 3 |
| `ICONST_4` | → 4 | 4 |
| `ICONST_5` | → 5 | 5 |
| `LCONST_0` | → 0L | 0 |
| `LCONST_1` | → 1L | 1 |
| `FCONST_0` | → 0.0f | 0.0 |
| `FCONST_1` | → 1.0f | 1.0 |
| `FCONST_2` | → 2.0f | 2.0 |
| `DCONST_0` | → 0.0 | 0.0 |
| `DCONST_1` | → 1.0 | 1.0 |
| `BIPUSH` | → byte | Push byte |
| `SIPUSH` | → short | Push short |
| `LDC` | → constant | Load constant |

### Variable Access

| Opcode | Effect | Type |
|--------|--------|------|
| `ILOAD`, `ISTORE` | int local | Integer |
| `LLOAD`, `LSTORE` | long local | Long |
| `FLOAD`, `FSTORE` | float local | Float |
| `DLOAD`, `DSTORE` | double local | Double |
| `ALOAD`, `ASTORE` | object local | Object (reference) |
| `ILOAD_0` through `ILOAD_3` | → local[n] | Load int var 0-3 |
| `ALOAD_0` | → this | Load 'this' (var 0) |
| `ALOAD_1` | → local[1] | Load object var 1 |

### Returns

| Opcode | Effect | Return Type |
|--------|--------|-------------|
| `RETURN` | (none) | void |
| `IRETURN` | ...int → | int |
| `LRETURN` | ...long → | long |
| `FRETURN` | ...float → | float |
| `DRETURN` | ...double → | double |
| `ARETURN` | ...object → | object |

### Control Flow

| Opcode | Effect | Condition |
|--------|--------|-----------|
| `GOTO` | Jump to label | Always |
| `IFEQ` | Pop int, jump if zero | int == 0 |
| `IFNE` | Pop int, jump if non-zero | int != 0 |
| `IFLT` | Pop int, jump if less than 0 | int < 0 |
| `IFLE` | Pop int, jump if less than or equal 0 | int <= 0 |
| `IFGT` | Pop int, jump if greater than 0 | int > 0 |
| `IFGE` | Pop int, jump if greater than or equal 0 | int >= 0 |
| `IF_ICMPEQ` | Pop 2 ints, jump if equal | int1 == int2 |
| `IF_ACMPEQ` | Pop 2 objects, jump if equal | obj1 == obj2 |

### Method Invocation

| Opcode | Effect | Type |
|--------|--------|------|
| `INVOKEVIRTUAL` | Call instance method | Normal method |
| `INVOKESPECIAL` | Call special method | Constructor, private, super |
| `INVOKESTATIC` | Call static method | Static method |
| `INVOKEINTERFACE` | Call interface method | Interface method |
| `INVOKEDYNAMIC` | Call dynamic method | Lambda, invokedynamic |

### Type Conversion

| Opcode | Conversion |
|--------|-----------|
| `I2L` | int → long |
| `I2F` | int → float |
| `I2D` | int → double |
| `L2I` | long → int |
| `L2F` | long → float |
| `L2D` | long → double |
| `F2I` | float → int |
| `F2L` | float → long |
| `F2D` | float → double |
| `D2I` | double → int |
| `D2L` | double → long |
| `D2F` | double → float |

## Practical Examples

### Example 1: Make Method a No-Op (Void)

```javascript
function initializeCoreMod() {
  return {
    'noOp': {
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

        for (var i = 0; i < classNode.methods.length; i++) {
          var method = classNode.methods[i];
          if (method.name === 'checkPacket' && method.desc === '(Lnet/minecraft/network/protocol/Packet;)V') {
            method.instructions.clear();
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

### Example 2: Return Default Value

```javascript
'transformer': function(classNode, environment) {
  var Opcodes = Java.type('org.objectweb.asm.Opcodes');
  var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');

  for (var i = 0; i < classNode.methods.length; i++) {
    var method = classNode.methods[i];
    if (method.name === 'getValue' && method.desc === '()I') {
      // Return 0 for int method
      method.instructions.clear();
      method.instructions.add(new InsnNode(Opcodes.ICONST_0));
      method.instructions.add(new InsnNode(Opcodes.IRETURN));
      break;
    }
  }
  return classNode;
}
```

### Example 3: Inject Logging

```javascript
'transformer': function(classNode, environment) {
  var Opcodes = Java.type('org.objectweb.asm.Opcodes');
  var FieldInsnNode = Java.type('org.objectweb.asm.tree.FieldInsnNode');
  var MethodInsnNode = Java.type('org.objectweb.asm.tree.MethodInsnNode');
  var LdcInsnNode = Java.type('org.objectweb.asm.tree.LdcInsnNode');
  var InsnList = Java.type('org.objectweb.asm.tree.InsnList');

  for (var i = 0; i < classNode.methods.length; i++) {
    var method = classNode.methods[i];
    if (method.name === 'myMethod') {
      // Insert at beginning: System.out.println("myMethod called")
      var insns = new InsnList();

      // System.out
      insns.add(new FieldInsnNode(Opcodes.GETSTATIC,
        'java/lang/System', 'out', 'Ljava/io/PrintStream;'));

      // "myMethod called"
      insns.add(new LdcInsnNode('myMethod called'));

      // println()
      insns.add(new MethodInsnNode(Opcodes.INVOKEVIRTUAL,
        'java/io/PrintStream', 'println', '(Ljava/lang/String;)V', false));

      // Insert before first instruction
      if (method.instructions.size() > 0) {
        method.instructions.insertBefore(method.instructions.get(0), insns);
      }

      break;
    }
  }
  return classNode;
}
```

## Type Descriptors

| Java Type | Descriptor | Example |
|-----------|-----------|---------|
| void | `V` | `()V` |
| int | `I` | `()I` |
| long | `J` | `()J` |
| float | `F` | `()F` |
| double | `D` | `()D` |
| boolean | `Z` | `()Z` |
| byte | `B` | `()B` |
| char | `C` | `()C` |
| short | `S` | `()S` |
| Object | `Ljava/lang/Object;` | `()Ljava/lang/Object;` |
| String | `Ljava/lang/String;` | `()Ljava/lang/String;` |
| int[] | `[I` | `()[I` |
| String[] | `[Ljava/lang/String;` | `()[Ljava/lang/String;` |

## Debugging

### Console Output

```javascript
console.log('[COREMOD] Message here');
console.log('[COREMOD] Variable: ' + variableName);
console.log('[COREMOD] Number: ' + intValue);
```

Logs appear in:
- Server: `logs/latest.log`
- Client: `.minecraft/logs/latest.log`

### Inspect Class

```javascript
console.log('[COREMOD] Class: ' + classNode.name);
console.log('[COREMOD] Interfaces: ' + classNode.interfaces);
console.log('[COREMOD] Methods: ' + classNode.methods.length);
for (var i = 0; i < classNode.methods.length; i++) {
  var m = classNode.methods[i];
  console.log('[COREMOD]   ' + m.name + m.desc);
}
```

### Inspect Instructions

```javascript
console.log('[COREMOD] Instructions: ' + method.instructions.size());
for (var i = 0; i < method.instructions.size(); i++) {
  var insn = method.instructions.get(i);
  console.log('[COREMOD]   ' + i + ': ' + insn.getClass().getSimpleName());
}
```

## References

- ASM Manual: https://asm.ow2.io/asm4-guide.pdf
- JVM Specification: https://docs.oracle.com/javase/specs/jvms/se17/html/
- Method Descriptors: https://docs.oracle.com/javase/specs/jvms/se17/html/jvms-4.html#jvms-4.3.3
