# NeoForge 21.1.x Network Negotiation Analysis

## Overview
NeoForge 21.1.x (for Minecraft 1.21.1) implements a sophisticated network negotiation system during the configuration phase to allow servers and clients to communicate incompatibilities and negotiate compatible channel sets.

## Key Components

### 1. Payload Types (Located in `src/main/java/net/neoforged/neoforge/network/payload/`)

#### CommonVersionPayload
- **ID**: `c:version`
- **Purpose**: First handshake - negotiate common networking protocol version
- **Format**: `VAR_INT` list of supported versions
- **Default**: Always sent with `[1]` (only version 1 is currently supported)

#### CommonRegisterPayload  
- **ID**: `c:register`
- **Purpose**: Second handshake - exchange play-phase channel lists
- **Format**: 
  - Version: VAR_INT (currently always 1)
  - Protocol: STRING_UTF8 (`play` or `configuration`)
  - Channels: Collection of Identifier resources

#### ModdedNetworkQueryPayload
- **ID**: `neoforge:register`
- **Purpose**: Server queries client for modded channels
- **Contains**: ModdedNetworkQueryComponent records with:
  - Identifier id
  - String version
  - Optional<PacketFlow> flow (CLIENT_BOUND, SERVER_BOUND, or none)
  - boolean optional

#### ModdedNetworkPayload
- **ID**: `neoforge:network`
- **Purpose**: Server sends final negotiated network setup to client
- **Contains**: NetworkPayloadSetup with all negotiated channels

### 2. Negotiation Flow

**Phase 1: Vanilla/NeoForge Detection**
- Server sends MinecraftRegisterPayload with builtin channel IDs
- If client doesn't respond with CommonVersionPayload → vanilla client → disconnect

**Phase 2: CommonVersionTask** (CommonVersionPayload exchange)
- Server: Sends CommonVersionPayload with `[1]`
- Client: Must respond with CommonVersionPayload containing at least `1` in version list
- **This is the critical first handshake**

**Phase 3: CommonRegisterTask** (CommonRegisterPayload exchange)
- Server: Sends CommonRegisterPayload for PLAY protocol with serverbound channels
- Client: Must respond with CommonRegisterPayload for PLAY protocol with clientbound channels

**Phase 4: Channel Negotiation**
- Both sides exchange ModdedNetworkQueryPayload with their channel lists
- NetworkComponentNegotiator validates compatibility:
  - Required channels must exist on both sides
  - Optional channels that don't exist are removed
  - Version must match or be unspecified
  - Flow direction must match

### 3. The Rejection Point

Your bot gets rejected with:
- Client message: `neoforge.network.negotiation.failure.vanilla.client.not_supported`
- Server log: "You are trying to connect to a server that is running NeoForge..."

This happens in `NetworkRegistry.initializeOtherConnection()` when:
1. Server doesn't receive CommonVersionPayload
2. Server treats connection as vanilla
3. Server negotiates empty channel list with vanilla expectations
4. Negotiation fails because server has required channels

The decision point is when the server receives the first custom payload. If it's NOT CommonVersionPayload or CommonRegisterPayload, the server calls `initializeOtherConnection()`.

## What Your Azalea Bot Needs to Do

To pass NeoForge negotiation:

1. **Detect the MinecraftRegisterPayload** during configuration phase
2. **Send CommonVersionPayload** with at least `[1]` as version list
3. **Handle CommonRegisterPayload** from server containing play channels
4. **Send back CommonRegisterPayload** with your client's channels (empty set for a bot is fine)
5. **Handle ModdedNetworkPayload** to register the negotiated channels
6. **Respond to configuration tasks** as needed

### Minimum Viable Implementation

For an azalea bot that has no custom channels:

1. Respond to any custom payload with ID `c:version` by sending:
   - Identifier: `c:version` 
   - Data: VAR_INT encoded list `[1]`

2. Respond to custom payload with ID `c:register` by sending:
   - Identifier: `c:register`
   - Data:
     - VAR_INT: 1 (version)
     - STRING_UTF8: "play" 
     - Collection of 0 identifiers (empty set)

3. Ignore `neoforge:network` and `neoforge:register` payloads

## Relevant Source Files

- `/home/bmerriam/neoforge-repo/src/main/java/net/neoforged/neoforge/network/ConfigurationInitialization.java`
- `/home/bmerriam/neoforge-repo/src/main/java/net/neoforged/neoforge/network/configuration/CommonVersionTask.java`
- `/home/bmerriam/neoforge-repo/src/main/java/net/neoforged/neoforge/network/configuration/CommonRegisterTask.java`
- `/home/bmerriam/neoforge-repo/src/main/java/net/neoforged/neoforge/network/payload/CommonVersionPayload.java`
- `/home/bmerriam/neoforge-repo/src/main/java/net/neoforged/neoforge/network/payload/CommonRegisterPayload.java`
- `/home/bmerriam/neoforge-repo/src/main/java/net/neoforged/neoforge/network/registration/NetworkRegistry.java` (lines 342-416)

