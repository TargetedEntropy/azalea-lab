# Azalea Lab - Minecraft Bot for Modded NeoForge Server

## What This Project Is

A proof-of-concept that connects a **Rust-based Minecraft bot** (using the Azalea library) to a
**heavily modded NeoForge 1.21.1 server** running the DynamicOdyssey 2.7.0 modpack (~100+ mods).

NeoForge normally rejects any client that isn't also running NeoForge. This project includes
three server-side patches that bypass that validation, allowing the lightweight Rust bot to
connect, join the game, and interact via chat.

### Key Specs

- **Minecraft**: 1.21.1 (protocol 774)
- **Server**: NeoForge 21.1.219
- **Modpack**: DynamicOdyssey 2.7.0
- **Bot**: Rust + Azalea (patched fork, nightly toolchain)
- **Auth**: Offline mode (no Microsoft/Mojang account needed)
- **Deployment**: Docker

---

## Repository Layout

```
modpack-azalea-lab/
├── CLAUDE.md                              # This file
│
├── server-deploy/                         # DEPLOYABLE PACKAGE (server + bot)
│   ├── build.sh                           # Assembles pack + patches from repo/
│   ├── run_bot.sh                         # Builds and runs the bot
│   ├── Dockerfile                         # Multi-stage NeoForge server build
│   ├── docker-compose.yml                 # Container config (port 25566)
│   ├── config/
│   │   ├── server.properties              # MC server settings (offline mode)
│   │   └── log4j2.xml                     # Logging (DEBUG to file, INFO to console)
│   ├── bot/                               # Azalea Rust bot (self-contained)
│   │   ├── src/main.rs                    # Bot source code
│   │   ├── Cargo.toml                     # Uses patched azalea + simdnbt
│   │   ├── Cargo.lock
│   │   └── patches/                       # Patched Rust crates
│   │       ├── azalea/                    # Full azalea workspace (17 crates)
│   │       └── simdnbt-0.6.1/            # Patched simdnbt dependency
│   ├── patches/                           # Server-side NeoForge bypass patches
│   │   ├── NegotiationPatch.java
│   │   ├── ConfigInitPatch.java
│   │   └── checkpatch-coremod-1.0.0.jar
│   └── pack/                              # Modpack files (mods, config, kubejs, etc.)
│
├── repo/                                  # ORIGINAL WORKING DIRECTORY
│   ├── bot/                               # Original bot source + patches
│   │   ├── src/main.rs
│   │   ├── Cargo.toml
│   │   └── patches/                       # Patched azalea + simdnbt
│   ├── server/                            # Server build context
│   │   ├── Dockerfile
│   │   ├── NegotiationPatch.java
│   │   ├── ConfigInitPatch.java
│   │   ├── CheckPacketPatcher.java        # Alternative approach (unused)
│   │   ├── checkpatch-coremod-1.0.0.jar   # Pre-built coremod
│   │   ├── build-coremod.sh               # Script to rebuild the coremod JAR
│   │   ├── coremod-jar/                   # Coremod source files
│   │   │   ├── META-INF/coremods.json
│   │   │   ├── META-INF/MANIFEST.MF
│   │   │   ├── META-INF/neoforge.mods.toml
│   │   │   ├── checkPacketTransformer.js
│   │   │   └── checkpacket_patch.js       # Active coremod transformer
│   │   └── DynamicOdyssey-Server-2.7.0/   # Extracted modpack
│   ├── docker-compose.yml
│   ├── scripts/run_bot.sh
│   ├── COMPLETE.md                        # Verification proof with timestamps
│   ├── RUNBOOK.md                         # Original run instructions
│   ├── START_HERE.md                      # Coremod introduction
│   ├── COREMOD_*.md                       # 6 detailed coremod docs
│   └── NEOFORGE_*.md                      # NeoForge analysis docs
│
├── azalea/                                # Upstream azalea-rs library (reference copy)
│   └── (17-crate Rust workspace)
│
├── DynamicOdyssey-2.7.0.zip              # Client modpack (20 MB)
├── DynamicOdyssey-Server-2.7.0.zip       # Server modpack (436 MB)
└── build_log.txt                          # Build log from original setup
```

---

## How to Deploy (Full Steps)

### Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Docker | 20.10+ | With Docker Compose v2 |
| Rust | nightly | `rustup toolchain install nightly` |
| RAM | 8 GB+ | Server uses 6 GB; bot needs ~1 GB to compile |
| Disk | ~2 GB | For Docker image build + Rust compilation |

### Step 1: Start the Server

```bash
cd server-deploy

# If pack/ and patches/ are empty, assemble them first:
./build.sh

# Build the Docker image and start the server
docker compose up -d

# Watch logs until you see "Done (X.XXXs)! For help, type "help""
docker logs -f azalea-mc-server
```

First build takes several minutes (NeoForge installer + mod loading).
Subsequent starts are much faster.

### Step 2: Run the Bot

```bash
# From the server-deploy directory:
./run_bot.sh
```

The bot will:
1. Connect to `localhost:25566` as `azalea_bot` (offline mode)
2. Wait 3 seconds after login
3. Send `"azalea-bot online"` in chat
4. Wait 2 seconds, then exit

### Step 3: Verify

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

### Connecting to a Remote Server

```bash
MC_HOST=10.0.0.5 MC_PORT=25566 ./run_bot.sh
```

### Changing the Server Port

```bash
MC_PORT=25577 docker compose up -d
```

### Stopping Everything

```bash
# Stop server (keeps world data via Docker volume)
docker compose down

# Stop server AND delete world data
docker compose down -v
```

---

## The Three Server Patches (Why They're Needed)

NeoForge 21.1.219 has three layers of validation that reject non-NeoForge clients.
Each patch disables one layer:

### 1. NegotiationPatch.java

**What it patches**: `net.neoforged.neoforge.network.negotiation.NetworkComponentNegotiator`

**Problem**: NeoForge requires clients to negotiate mod channels during connection.
The bot doesn't speak the NeoForge channel protocol, so negotiation fails.

**Fix**: Replaces the `negotiate()` method to always return success with an empty
component list, letting any client through.

**Applied**: At Docker build time — compiled and injected into
`neoforge-21.1.219-universal.jar` via `jar uf`.

### 2. ConfigInitPatch.java

**What it patches**: `net.neoforged.neoforge.network.ConfigurationInitialization`

**Problem**: During the configuration phase, NeoForge runs three checks that fail
for non-NeoForge clients:
- `RegistryDataMapNegotiation` — mod registry sync
- `CheckExtensibleEnums` — extensible enum validation
- `CheckFeatureFlags` — feature flag verification

**Fix**: Replaces the class to skip those three tasks. Still runs `SyncRegistries`,
`CommonVersionTask`, `CommonRegisterTask`, and `SyncConfig` if the client supports them.

**Applied**: Same as above — compiled and injected at Docker build time.

### 3. checkpatch-coremod-1.0.0.jar (ASM Coremod)

**What it patches**: `net.neoforged.neoforge.network.registration.NetworkRegistry.checkPacket()`

**Problem**: Even after passing negotiation and configuration, mods send custom
payloads to all connected clients. `checkPacket()` throws
`UnsupportedOperationException` for any payload type the client didn't register,
which disconnects the bot.

**Fix**: A NeoForge coremod (JavaScript + ASM bytecode transformation) that replaces
the entire `checkPacket()` method body with a single `RETURN` instruction at class
load time. The original method had 47 instructions; the patched version is a no-op.

**Applied**: At runtime — the JAR sits in the `mods/` folder and NeoForge's coremod
loader executes the JavaScript transformer before the class is loaded.

**Coremod source**: `repo/server/coremod-jar/`
**Rebuild**: `bash repo/server/build-coremod.sh`

---

## Bot Architecture

The bot uses **Azalea** (`azalea-rs`), a Rust library for Minecraft clients/bots.

### Why Patched Forks?

The bot depends on local patched copies of two crates (in `bot/patches/`):
- **azalea** — Full 17-crate workspace (auth, protocol, physics, inventory, etc.)
- **simdnbt** — NBT parsing library (patched for compatibility)

These are referenced via `path =` dependencies in `Cargo.toml` and `[patch.crates-io]`
overrides to ensure all transitive dependencies also use the patched versions.

### Rust Toolchain

The project requires **Rust nightly** (specified in `bot/patches/azalea/rust-toolchain`).

### Bot Code

`bot/src/main.rs` is ~30 lines:
- Creates an offline account (`azalea_bot`)
- Connects to `MC_HOST:MC_PORT` (defaults: `localhost:25566`)
- On `Event::Login`, sends a chat message and exits

---

## Rebuilding the Coremod

If you need to modify the coremod (e.g., to patch a different method):

1. Edit files in `repo/server/coremod-jar/`:
   - `META-INF/coremods.json` — target class mapping
   - `checkpacket_patch.js` — the active ASM transformer
2. Rebuild: `bash repo/server/build-coremod.sh`
3. Copy to server: the build script outputs `checkpatch-coremod-1.0.0.jar`

See `repo/COREMOD_GUIDE.md` and `repo/COREMOD_JAVASCRIPT_API.md` for the full
ASM/JavaScript API reference.

---

## Common Tasks

### Rebuild the Docker image from scratch
```bash
cd server-deploy
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Read server debug logs
```bash
docker exec azalea-mc-server cat /data/logs/latest.log
```

### Verify coremod loaded
```bash
docker logs azalea-mc-server 2>&1 | grep COREMOD
```
Expected: `[COREMOD CheckPacket] Method replaced with RETURN instruction`

### Run the bot against a different server
```bash
MC_HOST=my-server.example.com MC_PORT=25565 ./run_bot.sh
```

### Modify what the bot does
Edit `server-deploy/bot/src/main.rs`. The `handle()` function receives all game events.
After editing, just run `./run_bot.sh` again — cargo handles incremental rebuilds.

---

## Verified Working (2026-03-03)

Successfully tested end-to-end:
- Server: NeoForge 21.1.219 with DynamicOdyssey 2.7.0 (100+ mods)
- Bot: Connected as `azalea_bot`, sent chat message, exited cleanly
- Evidence: `repo/COMPLETE.md` with server log timestamps
