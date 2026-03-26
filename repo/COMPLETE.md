# COMPLETE - Azalea Bot + NeoForge 1.21.1 Server

## Server Pack

- **Zip**: `/home/bmerriam/modpack-azalea-lab/DynamicOdyssey-Server-2.7.0.zip`
- **Size**: 436M
- **SHA256**: `af321e849ec7fea7d36cb5ab57021ccd01325f76d3623adb1e2b8c29d8fd58ff`
- **Extracted to**: `server/DynamicOdyssey-Server-2.7.0/`

## Docker

- **Image**: `azalea-mc-neoforge:1.21.1`
- **Container**: `azalea-mc-server`
- **Port mapping**: `25566:25565` (host:container)
- **Minecraft version**: 1.21.1
- **NeoForge version**: 21.1.219
- **Java**: Eclipse Temurin 21

## How to Rerun Server

```bash
cd /home/bmerriam/modpack-azalea-lab/repo
docker compose up -d
docker logs -f azalea-mc-server
```

To rebuild from scratch:

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## How to Rerun Bot

```bash
/home/bmerriam/modpack-azalea-lab/repo/bot/target/release/azalea-bot
```

Or from source:

```bash
cd /home/bmerriam/modpack-azalea-lab/repo/bot
cargo run --release
```

The bot connects to `localhost:25566`, joins as `azalea_bot` (offline mode), sends "azalea-bot online" in chat, then exits.

## Offline Mode Configuration

- **server.properties**: `online-mode=false` (at `server/DynamicOdyssey-Server-2.7.0/server.properties`)
- **eula.txt**: `eula=true` (generated in Dockerfile: `RUN echo "eula=true" > eula.txt`)
- **Whitelist**: Disabled (`white-list=false`, `enforce-whitelist=false` in server.properties)
- **Bot auth**: Offline username `azalea_bot` (no Microsoft/Mojang auth)

## Patches Applied

1. **NegotiationPatch.java**: Replaces `NetworkComponentNegotiator` to always return negotiation success, allowing non-NeoForge clients to connect.
2. **ConfigInitPatch.java**: Replaces `ConfigurationInitialization` to skip RegistryDataMapNegotiation, CheckExtensibleEnums, and CheckFeatureFlags during client configuration.
3. **checkpatch-coremod-1.0.0.jar**: NeoForge coremod that patches `NetworkRegistry.checkPacket` at runtime to replace `ATHROW` with `POP+RETURN`, preventing disconnection when mods send payloads to non-NeoForge clients.

## Verification Evidence (2026-03-03 17:29 UTC)

- **MC 1.21.1 proof**: `ModLauncher running: args [--launchTarget, forgeserver, --fml.neoForgeVersion, 21.1.219, --fml.fmlVersion, 4.0.42, --fml.mcVersion, 1.21.1, --fml.neoFormVersion, 20240808.144430]`
- **NeoForge proof**: `NeoForge mod loading, version 21.1.219, for MC 1.21.1`
- **Bot join**: `[17:29:48] [Server thread/INFO] [minecraft/MinecraftServer]: azalea_bot joined the game`
- **Chat message**: `[17:29:51] [Server thread/INFO] [minecraft/MinecraftServer]: <azalea_bot> azalea-bot online`
- **Container time at verification**: `Tue Mar  3 05:30:05 PM UTC 2026` (14 seconds after chat message)
