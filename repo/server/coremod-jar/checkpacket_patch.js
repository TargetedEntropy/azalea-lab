var ASMAPI = Java.type('net.neoforged.coremod.api.ASMAPI');
var Opcodes = Java.type('org.objectweb.asm.Opcodes');
var InsnNode = Java.type('org.objectweb.asm.tree.InsnNode');

/**
 * Patches checkPacket methods to replace ATHROW with POP + RETURN.
 * Preserves the method body (including hasChannel call) so that
 * fabric-networking-api mixin injection points remain intact.
 * Only the final throw of UnsupportedOperationException is replaced.
 *
 * Stack state before ATHROW: [exception_ref]
 * POP removes it, RETURN returns normally from the void method.
 */
function initializeCoreMod() {
    return {
        'checkpacket_server': {
            'target': {
                'type': 'METHOD',
                'class': 'net.neoforged.neoforge.network.registration.NetworkRegistry',
                'methodName': 'checkPacket',
                'methodDesc': '(Lnet/minecraft/network/protocol/Packet;Lnet/minecraft/network/protocol/common/ServerCommonPacketListener;)V'
            },
            'transformer': function(method) {
                return patchCheckPacket(method, 'server');
            }
        },
        'checkpacket_client': {
            'target': {
                'type': 'METHOD',
                'class': 'net.neoforged.neoforge.network.registration.NetworkRegistry',
                'methodName': 'checkPacket',
                'methodDesc': '(Lnet/minecraft/network/protocol/Packet;Lnet/minecraft/network/protocol/common/ClientCommonPacketListener;)V'
            },
            'transformer': function(method) {
                return patchCheckPacket(method, 'client');
            }
        }
    };
}

function patchCheckPacket(method, variant) {
    ASMAPI.log('INFO', '[CheckPacketPatch] Patching checkPacket (' + variant + ')');

    var insns = method.instructions;
    var count = 0;

    for (var i = 0; i < insns.size(); i++) {
        var insn = insns.get(i);
        if (insn.getOpcode() === Opcodes.ATHROW) {
            // Stack before ATHROW: [exception_ref]
            // Replace ATHROW with POP (removes exception_ref) + RETURN
            var popInsn = new InsnNode(Opcodes.POP);
            insns.set(insn, popInsn);
            insns.insert(popInsn, new InsnNode(Opcodes.RETURN));
            count++;
            ASMAPI.log('INFO', '[CheckPacketPatch] Replaced ATHROW #' + count + ' with POP+RETURN');
        }
    }

    ASMAPI.log('INFO', '[CheckPacketPatch] Done: replaced ' + count + ' throw(s) in ' + variant);
    return method;
}
