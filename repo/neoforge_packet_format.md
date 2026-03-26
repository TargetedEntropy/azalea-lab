# NeoForge 21.1.x Negotiation Packets - Byte-Level Format

## Minecraft Protocol Basics

All custom payloads are sent as:
1. Packet ID (VAR_INT) - for custom payloads in configuration phase
2. Identifier (resource location) - the payload ID
3. Remaining bytes - the payload data

The `Identifier` format is:
- STRING_UTF8: namespace (e.g., "c" or "neoforge")
- STRING_UTF8: path (e.g., "version" or "register")

## CommonVersionPayload

**Identifier**: `c:version`

**Binary Format**:
```
[VAR_INT] list_length
[VAR_INT] version_1
[VAR_INT] version_2
...
[VAR_INT] version_N
```

**Example for `[1]`**:
- VAR_INT(1) = 0x01
- Bytes: 01

**Your Response**:
The bot should send with at least version `1` in the list. For simplicity, just send `[1]`:
- Payload data: `01` (VAR_INT list length of 1, containing one VAR_INT value 1)

## CommonRegisterPayload

**Identifier**: `c:register`

**Binary Format**:
```
[VAR_INT] version
[STRING_UTF8] protocol_id
[VAR_INT] channel_count
[Identifier] channel_1
[Identifier] channel_2
...
[Identifier] channel_N
```

**STRING_UTF8 format**:
- VAR_INT: string length in bytes
- BYTES: UTF-8 string data

**Identifier format** (for channels):
- STRING_UTF8: namespace
- STRING_UTF8: path

**Example for empty channels**:
```
01              // version = 1
04 70 6c 61 79  // STRING_UTF8("play") = 04 followed by "play"
00              // channel_count = 0 (no channels)
```

Breaking down STRING_UTF8("play"):
- 04 = length in bytes
- 70 6c 61 79 = "play" in UTF-8

## Complete Example Exchange

### Server sends CommonVersionPayload:
Client receives custom payload with ID `c:version` and data `01` (version list containing 1)

### Client responds:
Send custom payload `c:version` with data `01` (also sends version 1)

### Server sends CommonRegisterPayload:
Client receives custom payload with ID `c:register` and data for the server's play channels

### Client responds:
Send custom payload `c:register` with:
- Version: 1
- Protocol: "play"
- Channels: empty set

Full bytes for empty response:
```
01              // version = 1
04 70 6c 61 79  // STRING_UTF8("play")
00              // empty channel list
```

## What NOT to Do

- Don't send anything else before responding to `c:version`
- Don't skip the `c:register` handshake
- Don't send invalid UTF-8 in identifiers
- Don't send channels if you don't have them registered

## Debugging Tips

When capturing packets:
- Look for custom payload packets with IDs matching `c:version` (0x00 namespace, 0x07 path)
- Verify VAR_INT encoding (single byte for 0-127)
- Each STRING_UTF8 starts with a VAR_INT length
- The protocol name is always "play" (0x04) or "configuration" (0x0d)

