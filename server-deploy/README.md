# Azalea-Lab Server Deploy Package

A Rust-based Minecraft bot (Azalea) that connects to heavily modded NeoForge 1.21.1
servers, with OpenClaw integration for AI-powered chat via Discord.

Includes a single coremod (`azalea-bridge`) that allows the bot to coexist with
real NeoForge players on the same server — no NeoForge jar modifications needed.

## Prerequisites

- Docker & Docker Compose (for local server)
- Rust nightly toolchain (`rustup toolchain install nightly`)
- ~8 GB RAM (6 GB for MC server, ~1 GB for Rust compilation)

## Quick Start

```bash
# 1. Assemble the package from a modpack zip
./build.sh /path/to/DynamicOdyssey-Server-X.Y.Z.zip

# 2. Build and start the server
docker compose up -d
docker logs -f azalea-mc-server   # wait for "Done"

# 3. Run the bot (offline mode)
./run_bot.sh -u azalea_bot

# Or with Microsoft auth:
./run_bot.sh -e user@example.com

# Or against a remote server:
./run_bot.sh -s mc.example.com -p 25565 -e user@example.com
```

## Bot Usage

```
Usage: azalea-bot [OPTIONS]

Options:
  -s, --server <HOST>       MC server hostname         [env: MC_HOST]
  -p, --port <PORT>         MC server port             [env: MC_PORT]
  -u, --username <NAME>     Offline mode username      [env: BOT_USERNAME]
  -e, --email <EMAIL>       Microsoft auth email       [env: MS_EMAIL]
  -c, --config <PATH>       Path to TOML config file   [env: BOT_CONFIG]
      --openclaw-url <URL>  OpenClaw gateway URL       [env: OPENCLAW_URL]
      --openclaw-token <T>  OpenClaw bearer token      [env: OPENCLAW_TOKEN]
      --http-port <PORT>    Bot HTTP server port       [env: BOT_HTTP_PORT]
```

Config priority: **CLI flags > env vars > config file > defaults**

See `bot/config.example.toml` for a full config file template.

### Authentication

**Offline mode** (default): `-u azalea_bot`
- Works with `online-mode=false` servers, no Microsoft account needed

**Microsoft auth**: `-e user@example.com`
- Device-code OAuth flow — prints a URL and code to visit
- Tokens cached at `~/.minecraft/azalea-auth.json` (automatic refresh)
- Required for `online-mode=true` servers

### Bot HTTP API

The bot runs an HTTP server (default port 3001) for inbound commands:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Returns `"ok"` if bot is running |
| `/actions` | POST | Execute a bot action |

```bash
# Send a chat message through the bot
curl -X POST http://localhost:3001/actions \
  -H "Content-Type: application/json" \
  -d '{"action":"chat","message":"Hello from the API!"}'
```

## The Azalea Bridge Coremod

A single 4KB NeoForge coremod JAR (`azalea-bridge-2.5.0.jar`) dropped into the
server's `mods/` folder. Uses ASM bytecode transformation at class-load time.
**No NeoForge jar modifications. Real NeoForge players can connect alongside the bot.**

### What it patches

| Target | What it does |
|--------|-------------|
| `NetworkComponentNegotiator.negotiate()` | Preserves original result for real clients; overrides failed negotiation with empty success for the bot |
| `ConfigurationInitialization.configureModdedClient()` | Removes 3 problematic validation tasks (RegistryDataMapNegotiation, CheckExtensibleEnums, CheckFeatureFlags) |
| `NetworkRegistry` (entire class) | Neutralizes all `disconnect()` calls and `ATHROW` instructions so unknown payloads are silently ignored |

### Deploying to a remote server

Copy `azalea-bridge-2.5.0.jar` into the server's `mods/` folder and restart.
That's it — one file, no other changes needed.

### Rebuilding the coremod

```bash
# Edit the transformer
vim repo/server/coremod-jar-v2/azalea_bridge.js

# Rebuild
bash repo/server/build-coremod-v2.sh

# Copy to deploy
cp repo/server/azalea-bridge-*.jar server-deploy/patches/
```

### Verifying it loaded

```bash
grep AzaleaBridge logs/latest.log
```

Expected:
```
[AzaleaBridge] v2.5.0 loaded
[AzaleaBridge] negotiate() patched: N return point(s), failed results overridden
[AzaleaBridge] configureModdedClient(): Removed 3 problematic config task(s)
[AzaleaBridge] NetworkRegistry total: X disconnect(s), Y throw(s) neutralized
```

## OpenClaw Integration

The bot bridges Minecraft chat to [OpenClaw](https://github.com/openclaw/openclaw),
a self-hosted AI agent gateway for Discord and other channels.

- When a player mentions the bot's name in MC chat, the message is forwarded to
  OpenClaw via HTTP webhook, and the AI response is sent back as MC chat
- OpenClaw can send commands to the bot via `POST /actions` on the bot's HTTP server

Set `OPENCLAW_URL` and `OPENCLAW_TOKEN` (or use the config file) to enable.

## Server Configuration

| Setting | Default | Override |
|---------|---------|----------|
| Host port | 25566 | `MC_PORT=25577 docker compose up -d` |
| Server RAM | 4-6 GB | Edit `pack/user_jvm_args.txt` |
| Online mode | false (offline) | Edit `config/server.properties` |

## Updating the Modpack

```bash
./build.sh /path/to/DynamicOdyssey-Server-NEW_VERSION.zip
docker compose build
docker compose up -d
```

## Directory Layout

```
server-deploy/
├── build.sh              # Extracts modpack zip + copies coremod
├── run_bot.sh            # Build & run the bot (passes all args through)
├── Dockerfile            # NeoForge install (unmodified) + coremod in mods/
├── docker-compose.yml    # Container definition with world persistence
├── config/
│   ├── server.properties # MC server settings
│   └── log4j2.xml        # Logging config
├── bot/                  # Azalea Rust bot
│   ├── src/
│   │   ├── main.rs       # Entry point, auth, MC connection
│   │   ├── config.rs     # CLI flags, env vars, TOML config
│   │   ├── state.rs      # Shared state (Azalea Component + Arc)
│   │   ├── handler.rs    # Event handler (Login, Chat, Tick, etc.)
│   │   ├── bridge/       # OpenClaw HTTP bridge (inbound + outbound)
│   │   └── commands/     # BotAction enum + dispatcher
│   ├── config.example.toml
│   ├── Cargo.toml
│   └── patches/          # Patched azalea + simdnbt crates
├── patches/
│   └── azalea-bridge-*.jar   # The coremod (copied by build.sh)
└── pack/                 # Modpack files (extracted by build.sh)
```

## Stopping / Cleanup

```bash
# Stop (preserves world data)
docker compose down

# Stop and delete world data
docker compose down -v
```
