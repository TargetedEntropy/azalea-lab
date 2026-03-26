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
