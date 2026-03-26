# Azalea-Lab Server Deploy Package

Dockerized NeoForge 1.21.1 server (DynamicOdyssey 2.7.0 modpack) with patches
that allow non-NeoForge clients (like the Azalea Rust bot) to connect.

## Prerequisites

- Docker & Docker Compose
- Rust nightly toolchain (`rustup toolchain install nightly`)
- ~8 GB RAM available (6 GB allocated to MC server)

## Quick Start

```bash
# 1. Assemble the package (copies modpack + patches from repo)
./build.sh

# 2. Build the Docker image and start the server
docker compose up -d

# 3. Wait for startup (takes a few minutes with 100+ mods)
docker logs -f azalea-mc-server
# Wait for: "Done (X.XXXs)! For help, type "help""

# 4. Build and run the bot
./run_bot.sh

# Or connect to a remote server:
MC_HOST=10.0.0.5 MC_PORT=25566 ./run_bot.sh
```

## What the Patches Do

The server includes three patches that bypass NeoForge's strict client validation:

| Patch | Purpose |
|-------|---------|
| `NegotiationPatch.java` | Replaces `NetworkComponentNegotiator` to always return success, skipping NeoForge channel negotiation |
| `ConfigInitPatch.java` | Replaces `ConfigurationInitialization` to skip registry data map negotiation, extensible enum checks, and feature flag checks |
| `checkpatch-coremod-1.0.0.jar` | ASM coremod that replaces `NetworkRegistry.checkPacket()` with a no-op, preventing `UnsupportedOperationException` on unknown payloads |

## Configuration

| Setting | Default | Override |
|---------|---------|----------|
| Host port | 25566 | `MC_PORT=25577 docker compose up -d` |
| Server RAM | 4-6 GB | Edit `pack/user_jvm_args.txt` |
| Online mode | false (offline) | Edit `config/server.properties` |

## Directory Layout

```
server-deploy/
├── build.sh              # Assembles package from repo sources
├── run_bot.sh            # Build & run the bot (supports MC_HOST/MC_PORT env vars)
├── Dockerfile            # Multi-stage build: NeoForge install + patches
├── docker-compose.yml    # Container definition with world persistence
├── config/
│   ├── server.properties # MC server settings (offline mode, etc.)
│   └── log4j2.xml        # Logging config (DEBUG to file, INFO to console)
├── bot/                  # Azalea Rust bot
│   ├── src/main.rs       # Bot source (connects, sends chat msg, exits)
│   ├── Cargo.toml        # Dependencies (patched azalea + simdnbt)
│   ├── Cargo.lock
│   └── patches/          # Patched Rust crates (azalea, simdnbt)
├── patches/              # Server-side NeoForge patches (created by build.sh)
│   ├── NegotiationPatch.java
│   ├── ConfigInitPatch.java
│   └── checkpatch-coremod-1.0.0.jar
└── pack/                 # Modpack files (created by build.sh)
    ├── neoforge-21.1.219-installer.jar
    ├── mods/
    ├── config/
    ├── defaultconfigs/
    ├── kubejs/
    ├── plugins/
    ├── user_jvm_args.txt
    └── packwiz.json
```

## Stopping / Cleanup

```bash
# Stop (preserves world data)
docker compose down

# Stop and delete world data
docker compose down -v
```
