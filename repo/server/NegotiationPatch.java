package net.neoforged.neoforge.network.negotiation;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import net.minecraft.network.chat.Component;

/**
 * Patched NetworkComponentNegotiator that always returns negotiation success.
 * This allows non-NeoForge clients (like the azalea bot) to connect to
 * the modded server without implementing the full NeoForge channel protocol.
 */
public class NetworkComponentNegotiator {

    public static NegotiationResult negotiate(
            List<NegotiableNetworkComponent> server,
            List<NegotiableNetworkComponent> client) {
        // Always return success - allow any client to connect
        return new NegotiationResult(List.of(), true, Map.of());
    }

    private static List<NegotiableNetworkComponent> buildDisabledOptionalComponents(
            List<NegotiableNetworkComponent> currentSide,
            List<NegotiableNetworkComponent> otherSide) {
        return List.of();
    }

    public static Optional<ComponentNegotiationResult> validateComponent(
            NegotiableNetworkComponent left,
            NegotiableNetworkComponent right,
            String requestingSide) {
        return Optional.empty();
    }

    public record ComponentNegotiationResult(boolean success, Component failureReason) {}
}
