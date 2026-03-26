# NeoForge 21.1.x Quick Reference Card

## Two Payloads You Need to Handle

### Payload 1: `c:version`

**Trigger**: Server sends custom payload with ID `c:version`

**What to send back**:
```
Identifier: c:version
Data (hex): 01
Data (interpretation): VAR_INT list with 1 element: the value 1
```

**Rust example**:
```rust
let response = vec![0x01];
send_custom_payload("c:version", response);
```

---

### Payload 2: `c:register`

**Trigger**: Server sends custom payload with ID `c:register`

**What to send back**:
```
Identifier: c:register
Data (hex): 01 04 70 6C 61 79 00
Data breakdown:
  01           = VAR_INT version (1)
  04           = VAR_INT string length
  70 6C 61 79  = ASCII "play"
  00           = VAR_INT channel count (0)
```

**Rust example**:
```rust
let response = vec![
    0x01,                          // version
    0x04,                          // string length
    0x70, 0x6C, 0x61, 0x79,       // "play"
    0x00                           // channel count
];
send_custom_payload("c:register", response);
```

---

## Sequence Diagram

```
Client                          Server
   |                              |
   |<---- MinecraftRegister ------|
   |                              |
   |<---- c:version --------------|  (Server sends first)
   |                              |
   |---- c:version (respond) ---->|  (You MUST respond to this)
   |                              |
   |<---- c:register -------------|
   |                              |
   |---- c:register (respond) --->|  (Then respond to this)
   |                              |
   |<---- neoforge:network -------|  (Informational, ignore)
   |                              |
   |<---- FinishConfiguration ----|
   |                              |
   -------> PLAY PHASE <----------
```

---

## In Your Configuration Packet Handler

```rust
match custom_payload_id.as_str() {
    "c:version" => {
        // CRITICAL: Must respond first!
        send_custom_payload("c:version", vec![0x01]);
    }
    "c:register" => {
        // Then respond to this
        send_custom_payload("c:register",
            vec![0x01, 0x04, 0x70, 0x6C, 0x61, 0x79, 0x00]);
    }
    "neoforge:network" | "neoforge:register" => {
        // Informational, can ignore
    }
    _ => {
        // Other payloads handled normally
    }
}
```

---

## Binary Format Cheat Sheet

### VAR_INT Encoding
```
0x00 = 0
0x01 = 1
0x02 = 2
...
0x7F = 127
0x80 0x01 = 128
0xFF 0x01 = 255
```

For this task, you only need:
- 0x00 = 0
- 0x01 = 1
- 0x04 = 4

### STRING_UTF8 Encoding
```
[VAR_INT length] [UTF-8 bytes]

"play" = 04 70 6C 61 79
          ^  ^^^^^^^^^^^
          |  UTF-8 for "play" (4 bytes)
          length of 4
```

---

## Error Signs & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| "vanilla client not supported" | Didn't respond to `c:version` | Send `c:version` response first |
| Server disconnects immediately | Wrong packet format | Verify hex: `01 04 70 6C 61 79 00` |
| Still gets vanilla error | Responding to wrong identifier | Use exact IDs: `c:version`, `c:register` |
| Connection seems to work then fails | Not handling both payloads | Implement both c:version AND c:register |

---

## Copy-Paste Ready Response Data

### For `c:version`:
```
Hex: 01
Base64: AQ==
Bytes: [0x01]
```

### For `c:register`:
```
Hex: 01 04 70 6C 61 79 00
Base64: AQRwbGF5AA==
Bytes: [0x01, 0x04, 0x70, 0x6C, 0x61, 0x79, 0x00]
```

---

## Key Points to Remember

1. **Order matters** - Always respond to `c:version` before `c:register`
2. **Both are required** - Skip either one and negotiation fails
3. **Exact values only** - Don't improvise the bytes
4. **"play" is always the protocol** - Not "configuration" or other values
5. **Version 1 only** - Only supports version 1 currently
6. **Empty channels is fine** - Send 0x00 for channel count

---

## When To Implement

- During configuration phase packet handling
- After detecting MinecraftRegisterPayload (optional)
- Before FinishConfigurationPacket handling
- Same code path as other configuration packet processing

---

## Testing Checklist

- [ ] Vanilla server still works
- [ ] NeoForge server doesn't immediately disconnect
- [ ] Server log shows no negotiation errors
- [ ] Connection proceeds to play phase
- [ ] Gameplay works normally after connecting

---

## One-Liner Summary

**Respond with `0x01` to `c:version` and `0x01 0x04 0x70 0x6C 0x61 0x79 0x00` to `c:register` during configuration.**

That's all you need to do!
