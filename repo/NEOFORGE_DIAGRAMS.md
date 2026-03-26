# NeoForge 21.1.x Negotiation - Visual Diagrams

## 1. Network Negotiation Sequence

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Configuration Phase Sequence                              │
└─────────────────────────────────────────────────────────────────────────────┘

CLIENT                                                              SERVER
  │                                                                   │
  │  ◄────────────────── Connection Established ──────────────────  │
  │                                                                   │
  │  ◄─ MinecraftRegisterPayload (builtin channels) ─────────────  │
  │     (optional, informational)                                    │
  │                                                                   │
  ├─ Set up to listen for modded payloads                           │
  │                                                                   │
  │  ◄─ c:version payload (server says: "I support [1]") ────────  │
  │     Data: 0x01 (VAR_INT list containing 1)                      │
  │                                                                   │
  ├─ CRITICAL DECISION POINT ◄──────────────────────────────────┤
  │  Must respond within timeout or                                │
  │  server treats this as vanilla client                          │
  │                                                                   │
  │  c:version response (client says: "I support [1]") ──────────► │
  │     Data: 0x01 (VAR_INT list containing 1)                      │
  │                                                                   │
  │  ◄─ c:register payload (server lists channels) ───────────────  │
  │     Data format:                                                │
  │       - version: 1                                              │
  │       - protocol: "play"                                        │
  │       - channels: [server's channels...]                        │
  │                                                                   │
  │  c:register response (client lists channels) ──────────────────► │
  │     Data format:                                                │
  │       - version: 1                                              │
  │       - protocol: "play"                                        │
  │       - channels: [] (empty - bot has no channels)              │
  │                                                                   │
  │  ◄─ neoforge:network payload (negotiation result) ────────────  │
  │     (informational, contains final channel setup)               │
  │                                                                   │
  │  ◄─ Other config payloads (registries, etc) ─────────────────  │
  │                                                                   │
  │  ◄─ FinishConfiguration (enter play phase) ───────────────────  │
  │                                                                   │
  │  FinishConfiguration ACK ─────────────────────────────────────► │
  │                                                                   │
  └─ PLAY PHASE ──────────────────────────────────────────────────► │
```

## 2. The Rejection Path (What Happens if You Skip c:version)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    What Happens Without c:version Response                   │
└─────────────────────────────────────────────────────────────────────────────┘

CLIENT                                                              SERVER
  │                                                                   │
  │  ◄─ c:version payload ────────────────────────────────────────  │
  │                                                                   │
  │  ✓ Receives but doesn't respond                                 │
  │  ✗ OR responds to wrong payload                                 │
  │  ✗ OR timeout before responding                                 │
  │                                                                   │
  │                         ┌─ Timeout Expires ───────────┐         │
  │                         │                              │         │
  │                         ▼                              ▼         │
  │  ◄─ DISCONNECT ──── NetworkRegistry.initializeOtherConnection  │
  │     Message:          Treats as vanilla client                  │
  │     "You are trying    ↓                                         │
  │     to connect to a    Negotiates empty channels                │
  │     server that is     ↓                                         │
  │     running NeoForge"  Server has required channels             │
  │                        ↓                                         │
  │                        Negotiation FAILS                         │
  │                        ↓                                         │
  │                        DISCONNECT ──────────────────► │
  │                                                                   │
  └─ CONNECTION TERMINATED ────────────────────────────────────────┘
```

## 3. Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    NeoForge Network Components                               │
└─────────────────────────────────────────────────────────────────────────────┘

                         Minecraft 1.21.1 Server
                                  │
                                  ▼
                    ┌──────────────────────────┐
                    │  ServerConfigurationImpl  │
                    │ (Configuration Listener) │
                    └──────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
        ┌─────────────────────┐    ┌──────────────────────┐
        │ NetworkRegistry     │    │ ConfigurationInit    │
        │ (detects type)      │    │ (registers tasks)    │
        └─────────────────────┘    └──────────────────────┘
                    │                           │
        ┌───────────┴───────────┐              │
        │                       │              │
        ▼                       ▼              ▼
   ┌─────────┐         ┌──────────────┐ ┌──────────────┐
   │ Vanilla │         │ NeoForge     │ │ Tasks:       │
   │ Client  │ ────OR─ │ Client       │ │ - Version    │
   └─────────┘         └──────────────┘ │ - Register   │
        │                   │             └──────────────┘
        │                   │                    │
        ▼                   ▼                    ▼
   DISCONNECT      ┌──────────────────┐  ┌───────────────┐
                   │ Negotiator       │  │ Payloads:     │
                   │ (validates)      │  │ - c:version   │
                   └──────────────────┘  │ - c:register  │
                           │              │ - neoforge:*  │
                           ▼              └───────────────┘
                   ┌──────────────────┐
                   │ Success OR       │
                   │ ModdedNetworkSet │
                   │ upFailedPayload  │
                   └──────────────────┘
                           │
                    ┌──────┴──────┐
                    ▼             ▼
                  SUCCESS      FAILURE
                    │             │
                    ▼             ▼
              Play Phase      Disconnect
```

## 4. Byte Format Breakdown

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    c:version Payload Format                                  │
└─────────────────────────────────────────────────────────────────────────────┘

Custom Payload Packet:
┌────────────────────────────────────────────────────────────────┐
│ Packet ID (VAR_INT)                                             │
│ Identifier (Resource Location): "c:version"                     │
│ Payload Data:                                                   │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │ VAR_INT: List Length = 1                                 │   │
│ │ VAR_INT: Version Value = 1                               │   │
│ └──────────────────────────────────────────────────────────┘   │
│         Hex: 01                                                 │
│         Binary: 0000 0001                                       │
└────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                    c:register Payload Format                                 │
└─────────────────────────────────────────────────────────────────────────────┘

Custom Payload Packet:
┌────────────────────────────────────────────────────────────────┐
│ Packet ID (VAR_INT)                                             │
│ Identifier (Resource Location): "c:register"                    │
│ Payload Data:                                                   │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │ VAR_INT: Version = 1                       [01]           │   │
│ │ STRING_UTF8: Protocol = "play"                            │   │
│ │   Length: 4                              [04]            │   │
│ │   Data: p,l,a,y                          [70 6C 61 79]   │   │
│ │ VAR_INT: Channel Count = 0                [00]            │   │
│ └──────────────────────────────────────────────────────────┘   │
│         Hex: 01 04 70 6C 61 79 00                               │
│         Binary: 00000001 00000100 01110000 01101100 01100001   │
│                 01111001 00000000                               │
└────────────────────────────────────────────────────────────────┘
```

## 5. State Machine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Bot Connection State Machine                              │
└─────────────────────────────────────────────────────────────────────────────┘

                            ┌──────────────┐
                            │   Connected  │
                            │  (Handshake) │
                            └──────┬───────┘
                                   │
                                   ▼
                        ┌──────────────────────┐
                        │  Configuration Phase │
                        │  (Awaiting c:version)│
                        └──────┬───────────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
            ┌───────▼────────┐   ┌───────▼──────────┐
            │ Receive        │   │ Timeout /Other   │
            │ c:version      │   │ message first    │
            └───────┬────────┘   └───────┬──────────┘
                    │                     │
                    ▼                     ▼
        ┌─────────────────────┐  ┌──────────────┐
        │ Send c:version Resp │  │ Treated as   │
        │ (0x01)              │  │ vanilla      │
        │                     │  │              │
        │ Transition to       │  │ DISCONNECT   │
        │ c:register state    │  └──────────────┘
        └─────────┬───────────┘
                  │
                  ▼
       ┌──────────────────────┐
       │ Configuration Phase  │
       │ (Awaiting c:register)│
       └──────┬───────────────┘
              │
              ▼
   ┌──────────────────────────┐
   │ Receive c:register       │
   │ from server              │
   └──────┬───────────────────┘
          │
          ▼
 ┌───────────────────────────┐
 │ Send c:register Response  │
 │ (0x01 0x04 0x70...)      │
 │                           │
 │ Process other config      │
 │ packets (registries, etc) │
 └──────┬────────────────────┘
        │
        ▼
 ┌──────────────────┐
 │ Receive          │
 │ FinishConfig     │
 └──────┬───────────┘
        │
        ▼
 ┌──────────────────┐
 │  PLAY PHASE      │
 │  Connected!      │
 └──────────────────┘
```

## 6. Payload Identifier Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Resource Location (Identifier)                            │
└─────────────────────────────────────────────────────────────────────────────┘

Format: namespace:path

Examples:
┌──────────────────────────────────────────────────────────────┐
│ "c:version"        → namespace="c"      path="version"       │
│ "c:register"       → namespace="c"      path="register"      │
│ "neoforge:network" → namespace="neoforge" path="network"     │
│ "minecraft:brand"  → namespace="minecraft" path="brand"      │
└──────────────────────────────────────────────────────────────┘

In Binary (for c:version):
┌──────────────────────────────────────────────────────────────┐
│ STRING_UTF8("c"):                                             │
│   VAR_INT: 1 (length)           [01]                         │
│   Data: "c"                     [63]                         │
│                                                               │
│ STRING_UTF8("version"):                                       │
│   VAR_INT: 7 (length)           [07]                         │
│   Data: "version"               [76 65 72 73 69 6F 6E]       │
└──────────────────────────────────────────────────────────────┘
```

## 7. Complete Packet Exchange Timeline

```
Time →
│
├─ T0: Client sends login
│
├─ T1: Server sends LoginSuccess
│
├─ T2: Client transitions to Configuration phase
│
├─ T3: Server enters Configuration listener
│
├─ T4: Server sends MinecraftRegisterPayload (optional)
│       with builtin channel list
│
├─ T5: Server sends c:version payload
│       Data: 01 (version list [1])
│       ⚠ CLIENT MUST RESPOND SOON ⚠
│
├─ T6: [CRITICAL WINDOW ~30 seconds]
│       If no response → server treats as vanilla
│
├─ T7: Client sends c:version response  ← MUST BE IN CRITICAL WINDOW
│       Data: 01 (version list [1])
│
├─ T8: Server sends c:register payload
│       Data: 01 04 70 6c 61 79 [channels...]
│
├─ T9: Client sends c:register response
│       Data: 01 04 70 6c 61 79 00
│
├─ T10: Server sends neoforge:network payload
│        (negotiation result - informational)
│
├─ T11: Server sends FinishConfiguration packet
│
├─ T12: Client transitions to Play phase
│
└─ T13+: Gameplay continues
```

## 8. Error State Paths

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Possible Failure Modes                                    │
└─────────────────────────────────────────────────────────────────────────────┘

FAILURE #1: Timeout (No Response to c:version)
  server:c:version payload received → timeout → vanilla client → disconnect

FAILURE #2: Wrong Response to c:version
  server:c:version → client sends wrong payload → vanilla client → disconnect

FAILURE #3: Wrong Data Format
  client sends c:version with data: [00] or [02] → version mismatch → disconnect

FAILURE #4: Wrong Identifier
  client sends payload "neoforge:version" instead of "c:version" → vanilla → disconnect

FAILURE #5: Wrong c:register Response
  server sends c:register → client sends wrong format → parsing error → disconnect

FAILURE #6: Missing Protocol Name
  client sends c:register without "play" protocol → parsing error → disconnect

FAILURE #7: Wrong Negotiation
  either side has conflicting required channels → negotiation fails → disconnect
  (This shouldn't happen for a simple bot with 0 channels)

SUCCESS: All responses correct in correct order
  c:version response ✓ → c:register response ✓ → continue to play phase ✓
```

All correct responses needed for successful negotiation!
