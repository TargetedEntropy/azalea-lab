# Azalea Lab Runbook

## Overview

This repo runs a Minecraft 1.21.11 vanilla server in Docker and connects an Azalea (Rust) bot that sends a chat message to prove end-to-end connectivity.

## Prerequisites

- Docker & Docker Compose
- Rust toolchain (rustc / cargo)

## 1. Start the Minecraft Server

```bash
cd /home/bmerriam/modpack-azalea-lab/repo
docker compose up -d
```

- **Container name**: `azalea-mc-server`
- **Image**: `itzg/minecraft-server:java21`
- **Host port**: `25566` → container port `25565`
- **MC version**: 1.21.11 (protocol 774)

### Tail Server Logs

```bash
docker logs -f azalea-mc-server
```

Wait until you see: `Done (X.XXXs)! For help, type "help"`

## 2. Offline Mode Configuration

Offline mode is configured in two places:

### Server-side

- **File**: Set via `ONLINE_MODE: "FALSE"` environment variable in `docker-compose.yml`
- **Effect**: The `itzg/minecraft-server` image writes `online-mode=false` to `/data/server.properties` inside the container
- **Reference config**: `server/server.properties` (template in repo)

### Client/Bot-side

- The bot uses `Account::offline("azalea_bot")` in `bot/src/main.rs` — no Mojang/Microsoft auth required

## 3. Build and Run the Bot

### Build

```bash
cd /home/bmerriam/modpack-azalea-lab/repo/bot
cargo build --release
```

### Run

```bash
cargo run --release
```

Or use the convenience script:

```bash
./scripts/run_bot.sh
```

The bot will:
1. Connect to `localhost:25566`
2. Join as `azalea_bot` (offline account)
3. Wait 3 seconds
4. Send chat message: `azalea-bot online`
5. Wait 2 seconds, then exit

## 4. Verify

```bash
# Check container is running
docker ps

# Check for bot join and chat message
docker logs azalea-mc-server 2>&1 | grep -E "azalea|joined|chat|online"
```

Expected output:
```
azalea_bot[/...] logged in with entity id ...
azalea_bot joined the game
[Not Secure] <azalea_bot> azalea-bot online
azalea_bot left the game
```

## 5. Stop / Clean Up

```bash
# Stop server (keep data)
docker compose down

# Stop server and remove world data
docker compose down -v
```

## Debug Logging

The server uses a custom `log4j2.xml` (mounted from `server/log4j2.xml`) with:
- Console output at INFO level
- File output at DEBUG level (written to `/data/logs/latest.log` inside container)
- Network handler debug logging enabled

To read debug logs:
```bash
docker exec azalea-mc-server cat /data/logs/latest.log
```

## File Layout

```
repo/
├── docker-compose.yml      # Server container definition
├── server/
│   ├── log4j2.xml          # Debug logging config (mounted into container)
│   └── server.properties   # Reference server properties
├── bot/
│   ├── Cargo.toml          # Rust dependencies (azalea 0.15.1)
│   └── src/main.rs         # Bot source code
├── scripts/
│   └── run_bot.sh          # Convenience script to build & run bot
├── RUNBOOK.md              # This file
└── COMPLETE.md             # Verification proof
```
