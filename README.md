# Azalea Lab

A Rust-based Minecraft bot (using the [Azalea](https://github.com/azalea-rs/azalea) library) that connects to a heavily modded **NeoForge 1.21.1** server running the DynamicOdyssey 2.7.0 modpack (~100+ mods).

NeoForge normally rejects any client that isn't also running NeoForge. This project includes three server-side patches that bypass that validation, allowing the lightweight Rust bot to connect, join the game, and interact via chat — all without running a full Minecraft client.

## Key Specs

| Component | Detail |
|-----------|--------|
| Minecraft | 1.21.1 (protocol 774) |
| Server | NeoForge 21.1.219 |
| Modpack | DynamicOdyssey 2.7.0 |
| Bot | Rust + Azalea (patched fork, nightly toolchain) |
| Auth | Offline mode (no Microsoft/Mojang account needed) |
| Deployment | Docker |

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Docker | 20.10+ | With Docker Compose v2 |
| Rust | nightly | `rustup toolchain install nightly` |
| RAM | 8 GB+ | Server uses 6 GB; bot needs ~1 GB to compile |
| Disk | ~2 GB | For Docker image build + Rust compilation |

## Quick Start

```bash
cd server-deploy

# 1. Assemble modpack + patches (only needed once, or when updating the modpack)
./build.sh

# 2. Build and start the NeoForge server
docker compose up -d

# 3. Wait for server to finish loading (~2-5 minutes with 100+ mods)
docker logs -f azalea-mc-server
# Wait until you see: Done (X.XXXs)! For help, type "help"

# 4. Build and run the bot
./run_bot.sh
```

## Verify It Worked

```bash
docker logs azalea-mc-server 2>&1 | grep -E "azalea|joined|chat|online"
```

Expected output:
```
azalea_bot[/...] logged in with entity id ...
azalea_bot joined the game
[Not Secure] <azalea_bot> azalea-bot online
azalea_bot left the game
```

## Configuration

| Setting | Default | Override |
|---------|---------|----------|
| Server port | 25566 | `MC_PORT=25577 docker compose up -d` |
| Bot target host | localhost | `MC_HOST=10.0.0.5 ./run_bot.sh` |
| Bot target port | 25566 | `MC_PORT=25566 ./run_bot.sh` |
| Server RAM | 4-6 GB | Edit `server-deploy/pack/user_jvm_args.txt` |
| Online mode | false | Edit `server-deploy/config/server.properties` |

## Stopping / Cleanup

```bash
cd server-deploy

# Stop server (preserves world data)
docker compose down

# Stop server AND delete world data
docker compose down -v
```

## How the Patches Work

NeoForge has three layers of validation that reject non-NeoForge clients. Each patch disables one layer:

### 1. NegotiationPatch.java

Replaces `NetworkComponentNegotiator.negotiate()` to always return success with an empty component list, bypassing NeoForge channel negotiation. Applied at Docker build time by compiling and injecting into `neoforge-21.1.219-universal.jar`.

### 2. ConfigInitPatch.java

Replaces `ConfigurationInitialization` to skip three checks that fail for non-NeoForge clients: `RegistryDataMapNegotiation`, `CheckExtensibleEnums`, and `CheckFeatureFlags`. Applied the same way as patch 1.

### 3. checkpatch-coremod-1.0.0.jar (ASM Coremod)

A NeoForge coremod that replaces `NetworkRegistry.checkPacket()` with a no-op at class load time via ASM bytecode transformation. This prevents `UnsupportedOperationException` when mods send custom payloads to clients that didn't register for them. Placed in the `mods/` folder and loaded automatically by NeoForge.

## Bot Architecture

The bot source is at `server-deploy/bot/src/main.rs` (~30 lines). It:

1. Creates an offline account (`azalea_bot`)
2. Connects to `MC_HOST:MC_PORT` (defaults: `localhost:25566`)
3. On login, waits 3 seconds, sends `"azalea-bot online"` in chat
4. Waits 2 seconds, then exits

To change bot behavior, edit `server-deploy/bot/src/main.rs`. The `handle()` function receives all game events. Run `./run_bot.sh` again after editing — cargo handles incremental rebuilds.

The bot depends on patched forks of two crates (in `bot/patches/`):
- **azalea** — Full 17-crate workspace
- **simdnbt** — NBT parsing library

These are referenced via `path =` dependencies and `[patch.crates-io]` overrides in `Cargo.toml`.

## Repository Layout

```
modpack-azalea-lab/
├── README.md                        # This file
├── CLAUDE.md                        # Detailed project reference
├── server-deploy/                   # DEPLOYABLE PACKAGE
│   ├── build.sh                     # Assembles pack + patches from repo/
│   ├── run_bot.sh                   # Builds and runs the bot
│   ├── Dockerfile                   # Multi-stage NeoForge server build
│   ├── docker-compose.yml           # Container config (port 25566)
│   ├── config/                      # Server properties + logging
│   ├── bot/                         # Azalea Rust bot
│   │   ├── src/main.rs              # Bot source code
│   │   ├── Cargo.toml               # Dependencies
│   │   └── patches/                 # Patched azalea + simdnbt crates
│   ├── patches/                     # Server-side NeoForge bypass patches
│   └── pack/                        # Modpack files (mods, config, kubejs, etc.)
├── repo/                            # Original working directory + docs
│   ├── bot/                         # Original bot source + patches
│   ├── server/                      # Server build context + coremod source
│   └── *.md                         # Runbook, coremod guides, analysis docs
├── azalea/                          # Upstream azalea-rs (reference copy)
├── DynamicOdyssey-2.7.0.zip         # Client modpack
└── DynamicOdyssey-Server-2.7.0.zip  # Server modpack
```

---

## Instructions for Agentic Bots (AI Agents / LLM Agents)

This section provides structured instructions for AI coding agents (Claude Code, Cursor, Aider, OpenHands, etc.) that need to programmatically start the server, run the bot, modify bot behavior, or join a Minecraft server.

### Environment Check

Before doing anything, verify the prerequisites are available:

```bash
# Check Docker
docker --version && docker compose version

# Check Rust nightly
rustup run nightly rustc --version

# If nightly is missing:
rustup toolchain install nightly
```

### Starting the Server (Automated)

```bash
cd server-deploy

# Step 1: Assemble if pack/ is empty or missing
if [ ! -d pack ] || [ -z "$(ls pack/neoforge-*-installer.jar 2>/dev/null)" ]; then
  ./build.sh
fi

# Step 2: Build and start
docker compose up -d --build

# Step 3: Wait for server ready (poll logs)
until docker logs azalea-mc-server 2>&1 | grep -q 'Done ('; do
  sleep 5
done
echo "Server is ready."
```

**Important**: First build takes 3-10 minutes. Subsequent starts are faster (~1-2 min).

### Running the Bot (Automated)

```bash
cd server-deploy

# Default: connect to localhost:25566
./run_bot.sh

# Remote server:
MC_HOST=10.0.0.5 MC_PORT=25566 ./run_bot.sh
```

**Exit code 0** means success. The bot compiles on first run (~1-2 min), then runs in seconds.

### Verifying the Bot Connected

```bash
# Check server logs for bot activity
docker logs azalea-mc-server 2>&1 | tail -20 | grep -E "azalea_bot|joined|online"
```

Expected lines (all must be present for full success):
- `azalea_bot[/...] logged in with entity id ...`
- `azalea_bot joined the game`
- `[Not Secure] <azalea_bot> azalea-bot online`
- `azalea_bot left the game`

### Modifying Bot Behavior

The bot source is a single file: `server-deploy/bot/src/main.rs`

**Current behavior**: Connect → wait 3s → send chat message → wait 2s → exit.

To change what the bot does, edit the `handle()` function. It receives `Event` variants:

```rust
// Available events (non-exhaustive):
Event::Login          // Bot has joined the server
Event::Chat(msg)      // A chat message was received
Event::Tick           // Game tick (~20/sec while connected)
Event::Death          // Bot died
Event::Disconnect     // Disconnected from server
```

**Example: Make the bot stay connected and echo chat messages**

Replace the `handle()` function body in `server-deploy/bot/src/main.rs`:

```rust
async fn handle(bot: Client, event: Event, _state: State) -> anyhow::Result<()> {
    match event {
        Event::Login => {
            println!("[BOT] Logged in!");
            tokio::time::sleep(std::time::Duration::from_secs(3)).await;
            bot.chat("azalea-bot online");
        }
        Event::Chat(msg) => {
            let content = msg.content();
            println!("[BOT] Chat: {}", content);
            // Echo non-bot messages back
            if !content.contains("azalea_bot") {
                bot.chat(&format!("I heard: {}", content));
            }
        }
        _ => {}
    }
    Ok(())
}
```

After editing, run `./run_bot.sh` again. Cargo does incremental builds.

**Example: Change the bot's username**

In the `main()` function, change the `Account::offline()` argument:

```rust
let account = Account::offline("my_custom_name");
```

### Connecting to a Remote Server

If the NeoForge server is running on another machine (it must already have the three patches applied):

```bash
MC_HOST=<server-ip-or-hostname> MC_PORT=<port> ./run_bot.sh
```

The bot only works with servers that have all three patches applied. Connecting to an unpatched NeoForge server will fail during the negotiation phase.

### Full End-to-End Script for Agents

Copy-paste this to go from zero to a connected bot:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd server-deploy

# Assemble if needed
if [ ! -d pack ] || [ -z "$(ls pack/neoforge-*-installer.jar 2>/dev/null)" ]; then
  ./build.sh
fi

# Start server
docker compose up -d --build

# Wait for server ready
echo "Waiting for server to start..."
for i in $(seq 1 120); do
  if docker logs azalea-mc-server 2>&1 | grep -q 'Done ('; then
    echo "Server ready after ~$((i * 5)) seconds."
    break
  fi
  if [ "$i" -eq 120 ]; then
    echo "ERROR: Server did not start within 10 minutes."
    docker logs azalea-mc-server 2>&1 | tail -30
    exit 1
  fi
  sleep 5
done

# Run the bot
./run_bot.sh

# Verify
echo "--- Verification ---"
docker logs azalea-mc-server 2>&1 | grep -E "azalea_bot|joined|online" | tail -5
```

### Troubleshooting for Agents

| Symptom | Cause | Fix |
|---------|-------|-----|
| `build.sh` fails with "No zip provided and pack/ is empty" | Modpack not extracted | Run `./build.sh /path/to/DynamicOdyssey-Server-2.7.0.zip` |
| Docker build fails at NeoForge installer | Missing `pack/neoforge-*-installer.jar` | Re-run `./build.sh` |
| Bot fails to compile | Missing Rust nightly | `rustup toolchain install nightly` |
| Bot connects then immediately disconnects | Server patches not applied | Rebuild Docker image: `docker compose build --no-cache` |
| `Connection refused` | Server not running or wrong port | Check `docker ps` and verify `MC_PORT` |
| Server takes too long to start | Normal for 100+ mods | Wait up to 10 minutes on first boot |
| Coremod not loading | JAR not in mods/ | Check `docker logs azalea-mc-server 2>&1 \| grep COREMOD` |

### Key Constraints for Agents

- **Rust nightly is required.** The patched azalea crate uses nightly features.
- **The server must be in offline mode** (`online-mode=false` in `server.properties`). The bot uses `Account::offline()` which does not authenticate with Mojang/Microsoft.
- **All three patches are required.** Removing any one will cause the bot to be rejected.
- **The bot binary is not cross-compiled.** It must be built on the same architecture it runs on.
- **First compilation is slow** (~1-2 min). Subsequent runs use incremental builds and are fast.
- **The `patches/` directories are large** (full azalea workspace = 17 crates). Do not delete them.
