# NeoForge 21.1.x Network Negotiation Documentation

This directory contains comprehensive documentation for implementing NeoForge 21.1.x network negotiation support in the Azalea bot.

## Quick Start

**Problem**: Bot gets rejected by NeoForge servers with "vanilla client not supported" error

**Solution**: Implement two custom payload responses during the configuration phase

**Time to implement**: ~30 minutes for experienced developers

## Documentation Files

### 1. [NEOFORGE_21_1_SUMMARY.md](./NEOFORGE_21_1_SUMMARY.md) - START HERE
**Purpose**: Executive summary with overview and error analysis
**Contains**:
- What went wrong and why
- Packet format tables
- Negotiation flow diagram
- Implementation checklist
- Source code references

**Read this first for understanding the problem.**

### 2. [NEOFORGE_IMPLEMENTATION.md](./NEOFORGE_IMPLEMENTATION.md) - IMPLEMENTATION GUIDE
**Purpose**: Step-by-step implementation with code examples
**Contains**:
- Root cause analysis
- Implementation steps with pseudocode
- Rust code examples
- Byte-level helpers
- Testing guidance
- Common mistakes

**Read this second to implement the solution.**

### 3. [neoforge_analysis.md](./neoforge_analysis.md) - TECHNICAL DEEP DIVE
**Purpose**: Detailed technical analysis of NeoForge negotiation
**Contains**:
- Overview of network negotiation
- Key components (payloads, tasks)
- Complete negotiation flow
- Rejection point analysis
- Relevant source files

**Read this for deeper understanding.**

### 4. [neoforge_packet_format.md](./neoforge_packet_format.md) - PACKET FORMATS
**Purpose**: Byte-level packet format specifications
**Contains**:
- Binary format for each payload
- VAR_INT and STRING_UTF8 explanations
- Complete example exchanges
- Debugging tips
- Hex dump examples

**Reference this while implementing.**

## The Problem in 30 Seconds

NeoForge servers require clients to perform a handshake during the configuration phase:

1. Server sends `c:version` payload
2. **Client MUST respond** with `c:version` payload
3. Server sends `c:register` payload  
4. Client responds with `c:register` payload

If the bot doesn't respond to step 2, the server treats it as a vanilla client and disconnects.

## The Solution in 30 Seconds

Add this to your configuration phase packet handler:

```rust
if payload_id == "c:version" {
    send_payload("c:version", vec![0x01]);
} else if payload_id == "c:register" {
    send_payload("c:register", vec![0x01, 0x04, 0x70, 0x6C, 0x61, 0x79, 0x00]);
}
```

That's it! (See NEOFORGE_IMPLEMENTATION.md for the full context)

## Key Facts

- **Only two channels need to be implemented**: `c:version` and `c:register`
- **Protocol is always "play"**: Not "configuration"
- **Version is always 1**: Current NeoForge only supports version 1
- **Empty channel list is OK**: Bot doesn't need to support any mods
- **Order matters**: `c:version` must be answered first

## Files in NeoForge Repository

The analysis was based on NeoForge 1.21.x source:
- CommonVersionPayload.java (42 lines)
- CommonRegisterPayload.java (50 lines)
- NetworkRegistry.java (600+ lines, key sections analyzed)
- NetworkComponentNegotiator.java (191 lines)
- ConfigurationInitialization.java
- CommonVersionTask.java & CommonRegisterTask.java

All extracted from: https://github.com/neoforged/NeoForge/tree/1.21.x

## Testing

1. Test against vanilla MC 1.21.1 (should still work)
2. Test against NeoForge 21.1.219+ server
3. Check server logs - should NOT show negotiation failure
4. Verify connection proceeds to play phase

## Implementation Checklist

- [ ] Read NEOFORGE_21_1_SUMMARY.md (5 min)
- [ ] Review NEOFORGE_IMPLEMENTATION.md (10 min)
- [ ] Identify configuration packet handler location in code (5 min)
- [ ] Implement c:version response (10 min)
- [ ] Implement c:register response (10 min)
- [ ] Test locally (5 min)
- [ ] Test against NeoForge server (10 min)

**Total time**: ~45 minutes

## Common Issues

**"Server still rejects me"**
- Did you respond to `c:version` FIRST?
- Is the response data exactly `0x01`?
- Is the `c:register` response in the right format?

**"I'm sending the right data but still failing"**
- Make sure you're not sending other payloads before the handshake
- Check that you're using the exact channel IDs: `c:version`, `c:register`
- Verify the string "play" is UTF-8 encoded correctly

**"How do I know if it's working?"**
- Enable debug logging to see when payloads are received
- Check server logs - error should mention specific mods, not generic "vanilla client"
- You should see both c:version and c:register exchanges in logs

## Questions?

Refer to the specific documentation file:
- **"Why am I getting rejected?"** → NEOFORGE_21_1_SUMMARY.md
- **"How do I implement this?"** → NEOFORGE_IMPLEMENTATION.md
- **"What are the exact bytes?"** → neoforge_packet_format.md
- **"Why does NeoForge do this?"** → neoforge_analysis.md

## Next Steps

1. Open **NEOFORGE_21_1_SUMMARY.md**
2. Read the Executive Summary section
3. Check your understanding against the error analysis
4. Move to **NEOFORGE_IMPLEMENTATION.md**
5. Implement the solution
6. Test against both vanilla and NeoForge servers
