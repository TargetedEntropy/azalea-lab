import org.objectweb.asm.*;
import org.objectweb.asm.tree.*;
import java.io.*;
import java.util.jar.*;
import java.util.zip.*;

/**
 * Patches NetworkRegistry.checkPacket methods to be no-ops using ASM tree API.
 * Outputs the patched .class file to a directory for use with jar uf.
 *
 * Usage: java -cp asm-9.8.jar:asm-tree-9.8.jar:. CheckPacketPatcher <jar-path> <output-dir>
 */
public class CheckPacketPatcher {

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: java CheckPacketPatcher <neoforge-jar> <output-dir>");
            System.exit(1);
        }
        String jarPath = args[0];
        String outputDir = args[1];
        String targetEntry = "net/neoforged/neoforge/network/registration/NetworkRegistry.class";

        // Read the original class from the jar
        byte[] originalBytes;
        try (JarFile jar = new JarFile(jarPath)) {
            ZipEntry entry = jar.getEntry(targetEntry);
            if (entry == null) {
                System.err.println("Class not found in jar: " + targetEntry);
                System.exit(1);
            }
            try (InputStream is = jar.getInputStream(entry)) {
                originalBytes = is.readAllBytes();
            }
        }

        // Parse into ClassNode (tree API) for safe modification
        ClassReader cr = new ClassReader(originalBytes);
        ClassNode cn = new ClassNode();
        cr.accept(cn, 0);

        // Patch all checkPacket methods: replace throw with return
        int patched = 0;
        for (MethodNode mn : cn.methods) {
            if ("checkPacket".equals(mn.name)) {
                // Replace method body with just RETURN
                mn.instructions.clear();
                mn.tryCatchBlocks.clear();
                if (mn.localVariables != null) mn.localVariables.clear();
                mn.instructions.add(new InsnNode(Opcodes.RETURN));
                mn.maxStack = 0;
                mn.maxLocals = 3;
                patched++;
                System.out.println("  Patched method: " + mn.name + mn.desc);
            }
        }

        if (patched == 0) {
            System.err.println("No checkPacket methods found!");
            System.exit(1);
        }

        // Write patched class to output directory
        ClassWriter cw = new ClassWriter(0);
        cn.accept(cw);
        byte[] patchedBytes = cw.toByteArray();

        File outFile = new File(outputDir, targetEntry);
        outFile.getParentFile().mkdirs();
        try (FileOutputStream fos = new FileOutputStream(outFile)) {
            fos.write(patchedBytes);
        }

        System.out.println("Wrote patched class to: " + outFile.getPath());
        System.out.println("Patched " + patched + " checkPacket method(s)");
    }
}
