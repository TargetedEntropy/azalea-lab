# NeoForge 21.1.x Network Negotiation - Complete Analysis

## Executive Summary

Your Azalea bot is being rejected by NeoForge 21.1 servers because it doesn't respond to the `c:version` custom payload during the configuration phase. The server requires a specific handshake before allowing the connection to proceed.

**The Fix**: Implement two custom payload responses:
1. `c:version` - respond with payload data `[0x01]` (version list [1])
2. `c:register` - respond with payload data `[0x01, 0x04, 0x70, 0x6C, 0x61, 0x79, 0x00]` (version 1, protocol "play", 0 channels)

## What We Found

### 1. Custom Payload Channels Used by NeoForge

| Channel ID | Direction | Purpose | Status |
|-----------|-----------|---------|--------|
| `c:version` | Bidirectional | Negotiate common protocol version | **REQUIRED** |
| `c:register` | Bidirectional | Exchange play-phase channel lists | **REQUIRED** |
| `neoforge:network` | Server→Client | Send negotiated channels | Informational |
| `neoforge:register` | Server→Client | Query client channels | Informational |

### 2. Packet Format Details

#### CommonVersionPayload (`c:version`)

**Binary Format**: `[VAR_INT list_length] [VAR_INT version1] [VAR_INT version2] ...`

**Example Response** (for simplicity):
```
Hex: 01
Meaning: VAR_INT(1) = a list with one element: VAR_INT(1)
```

#### CommonRegisterPayload (`c:register`)

**Binary Format**:
```
[VAR_INT version]
[STRING_UTF8 protocol_name]
[VAR_INT channel_count]
[Identifier channel_1]...
```

**Example Response** (empty channels):
```
Hex: 01 04 70 6C 61 79 00
Meaning:
  01           = version 1
  04           = STRING_UTF8 length (4 bytes)
  70 6C 61 79  = "play" in UTF-8
  00           = VAR_INT(0) = no channels
```

### 3. Negotiation Flow

```
Client connects to NeoForge server
    ↓
Server enters Configuration phase
    ↓
Server sends MinecraftRegisterPayload (vanilla protocol)
    ↓
Server sends CommonVersionPayload (c:version)
    ↓ [CRITICAL POINT]
Client MUST respond with c:version ← THIS IS WHERE YOUR BOT FAILS
    ↓
If no response → Server calls initializeOtherConnection()
    ↓
Server disconnects with: "You are trying to connect to a server that is running NeoForge, but you are not."
```

### 4. Error Analysis

Your bot gets the error:
```
Client: neoforge.network.negotiation.failure.vanilla.client.not_supported
Server: You are trying to connect to a server that is running NeoForge, but you are not.
```

**Root cause**: In `NetworkRegistry.initializeOtherConnection()` (line 398-401 of source):
```java
if (!negotiationResult.success()) {
    listener.disconnect(Component.translatableWithFallback(
        "neoforge.network.negotiation.failure.vanilla.client.not_supported",
        "You are trying to connect to a server that is running NeoForge, but you are not..."
    ));
}
```

This happens when:
1. Server doesn't receive `c:version` response from client
2. Server treats connection as vanilla
3. Server has required (non-optional) NeoForge channels
4. Negotiation with empty client channel set fails

## Implementation Guide

See `NEOFORGE_IMPLEMENTATION.md` for complete Rust pseudocode and implementation examples.

### Quick Implementation Checklist

- [ ] Detect `c:version` custom payload in configuration phase
- [ ] Create response: `0x01` (list [1])
- [ ] Send response as custom payload with ID `c:version`
- [ ] Detect `c:register` custom payload
- [ ] Create response: `0x01 0x04 0x70 0x6C 0x61 0x79 0x00`
- [ ] Send response as custom payload with ID `c:register`
- [ ] Ignore `neoforge:network` and `neoforge:register` payloads
- [ ] Proceed normally to play phase

## Key Facts

1. **NeoForge uses "c:" namespace** - The "c" stands for "common" networking protocol
2. **Version 1 is the only version** - Currently no version 2 exists
3. **Protocol must be "play"** - Always "play", not "configuration"
4. **Empty channel list is OK** - You don't need to support any mods' channels
5. **Order matters** - `c:version` must come FIRST, then `c:register`
6. **VAR_INT encoding** - All numbers use Minecraft's variable-length integer encoding

## Source Code References

All source code was extracted from NeoForge 1.21.x branch:
- https://github.com/neoforged/NeoForge/tree/1.21.x

Key files analyzed:
- `src/main/java/net/neoforged/neoforge/network/payload/CommonVersionPayload.java` (42 lines)
- `src/main/java/net/neoforged/neoforge/network/payload/CommonRegisterPayload.java` (50 lines)
- `src/main/java/net/neoforged/neoforge/network/registration/NetworkRegistry.java` (600+ lines, analyzed key sections)
- `src/main/java/net/neoforged/neoforge/network/negotiation/NetworkComponentNegotiator.java` (191 lines)
- `src/main/java/net/neoforged/neoforge/network/configuration/CommonVersionTask.java` (32 lines)
- `src/main/java/net/neoforged/neoforge/network/configuration/CommonRegisterTask.java` (37 lines)

## Files Included in This Package

1. **NEOFORGE_IMPLEMENTATION.md** - Complete implementation guide with Rust pseudocode
2. **neoforge_analysis.md** - Detailed technical analysis of negotiation components
3. **neoforge_packet_format.md** - Byte-level packet format specifications
4. **NEOFORGE_21_1_SUMMARY.md** - This file

## Testing Your Implementation

After implementing the handshake:

1. **Verify locally** against a vanilla MC 1.21.1 server (should work as before)
2. **Test against NeoForge 21.1.219+** server
3. **Check debug logs** for:
   - "Received NeoForge c:version negotiation"
   - "Received NeoForge c:register negotiation"
   - Server should NOT show negotiation failure
4. **Confirm successful connection** to play phase

## Additional Notes

### Why This Happens

NeoForge implements a sophisticated channel negotiation system to:
- Allow servers to require specific mods
- Detect incompatible clients early (during configuration, not play)
- Gracefully disconnect with helpful error messages

### Why Your Bot Needs This

The official Minecraft client implements this negotiation in its packet listeners. Your bot, being a custom implementation, needs to replicate this behavior.

### Future-Proofing

The current implementation hardcodes version `1`. If NeoForge ever releases a version 2 protocol, you may need to update. However:
- This is unlikely soon
- The system is designed for backward compatibility
- Your implementation will still work with future servers (they support multiple versions)

## Next Steps

1. Review `NEOFORGE_IMPLEMENTATION.md` for detailed implementation
2. Identify where to add the custom payload handlers in your codebase
3. Implement the two response functions
4. Test against both vanilla and NeoForge servers
5. Consider adding optional logging/debugging output

Good luck with your implementation!
