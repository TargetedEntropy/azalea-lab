# Azalea NeoForge 21.1.x Negotiation Implementation Guide

## The Problem

Your bot gets rejected by NeoForge servers with:
```
Client: neoforge.network.negotiation.failure.vanilla.client.not_supported
Server: You are trying to connect to a server that is running NeoForge, but you are not.
```

## Root Cause

The NeoForge server expects a specific handshake during the configuration phase:
1. Server sends `c:version` custom payload
2. Client must respond with `c:version` custom payload
3. Server sends `c:register` custom payload
4. Client must respond with `c:register` custom payload

If the bot doesn't respond to `c:version` first, the server classifies it as a vanilla client and disconnects it.

## Implementation Steps

### Step 1: Detect NeoForge Negotiation

In your configuration phase packet handler, when you receive a `ClientboundCustomPayloadPacket`:

```rust
match payload_identifier {
    Identifier { namespace: "c", path: "version" } => {
        // This is the critical NeoForge negotiation packet
        handle_c_version(payload_data).await
    }
    Identifier { namespace: "c", path: "register" } => {
        handle_c_register(payload_data).await
    }
    _ => {
        // Other payloads can be ignored for now
    }
}
```

### Step 2: Respond to c:version

When you receive the `c:version` payload:

```rust
async fn handle_c_version(payload_data: &[u8]) {
    // The payload is a list of VAR_INT versions
    // For NeoForge 21.1, it will be [1]
    // You only need to support version 1

    // Send back the same format: list with [1]
    let response = create_c_version_response();
    send_custom_payload("c:version", response).await
}

fn create_c_version_response() -> Vec<u8> {
    // Format: VAR_INT(list_length) + [VAR_INT(version)]
    // For version list [1]:
    vec![0x01]  // VAR_INT list length = 1, element value = 1
}
```

### Step 3: Respond to c:register

When you receive the `c:register` payload:

```rust
async fn handle_c_register(payload_data: &[u8]) {
    // The server sends:
    // - VAR_INT version (always 1)
    // - STRING_UTF8 protocol ("play" or "configuration")
    // - Collection of identifiers (the channels the server supports)

    // You must respond with:
    // - VAR_INT version = 1
    // - STRING_UTF8 protocol = "play"
    // - Empty collection (you have no channels)

    let response = create_c_register_response();
    send_custom_payload("c:register", response).await
}

fn create_c_register_response() -> Vec<u8> {
    // Format:
    // VAR_INT(1) = version
    // STRING_UTF8("play") = protocol
    // VAR_INT(0) = channel count (empty list)

    let mut buf = Vec::new();
    buf.push(0x01);  // version = 1

    // STRING_UTF8("play")
    buf.push(0x04);  // length = 4
    buf.extend_from_slice(b"play");

    buf.push(0x00);  // channel_count = 0

    buf
}
```

### Step 4: Integrated Configuration Handler

Here's how it fits into your existing configuration phase:

```rust
pub fn process_configuration_packet(
    entity: Entity,
    packet: ClientboundConfigurationPacket,
) {
    match packet {
        ClientboundConfigurationPacket::CustomPayload(p) => {
            match p.identifier.as_str() {
                // NeoForge negotiation phase
                "c:version" => {
                    debug!("Received NeoForge c:version negotiation");
                    let response = create_c_version_response();
                    send_custom_payload_to_server(entity, "c:version", response);
                }
                "c:register" => {
                    debug!("Received NeoForge c:register negotiation");
                    let response = create_c_register_response();
                    send_custom_payload_to_server(entity, "c:register", response);
                }
                "neoforge:network" => {
                    // This is informational - the negotiated channels
                    debug!("Received NeoForge channel negotiation result");
                }
                "neoforge:register" => {
                    // Server's modded channel query - can be ignored
                    debug!("Received NeoForge channel query");
                }
                id => {
                    debug!("Received unknown custom payload: {}", id);
                }
            }
        }

        // ... handle other configuration packets ...

        ClientboundConfigurationPacket::FinishConfiguration(_) => {
            // Ready to transition to play phase
            send_finish_configuration_packet(entity);
        }
    }
}
```

### Step 5: Helper Function for Sending Custom Payloads

```rust
fn send_custom_payload_to_server(
    entity: Entity,
    identifier: &str,
    data: Vec<u8>,
) {
    let packet = ServerboundCustomPayloadPacket {
        identifier: Identifier::from(identifier),
        data: data.into(),  // UnsizedByteArray
    };

    // Send through your normal packet sending mechanism
    send_configuration_packet(entity, packet);
}
```

### Step 6: Byte-Level Helpers (if building manually)

```rust
// Helper to encode VAR_INT
fn encode_var_int(value: i32) -> Vec<u8> {
    let mut result = Vec::new();
    let mut val = value as u32;
    loop {
        let mut temp = (val & 0x7F) as u8;
        val >>= 7;
        if val != 0 {
            temp |= 0x80;
        }
        result.push(temp);
        if val == 0 {
            break;
        }
    }
    result
}

// Helper to encode STRING_UTF8
fn encode_string_utf8(s: &str) -> Vec<u8> {
    let bytes = s.as_bytes();
    let mut result = encode_var_int(bytes.len() as i32);
    result.extend_from_slice(bytes);
    result
}

// Alternative implementation of c:version response
fn create_c_version_response_v2() -> Vec<u8> {
    let mut buf = Vec::new();
    buf.extend(encode_var_int(1));  // list length
    buf.extend(encode_var_int(1));  // version number
    buf
}

// Alternative implementation of c:register response
fn create_c_register_response_v2() -> Vec<u8> {
    let mut buf = Vec::new();
    buf.extend(encode_var_int(1));               // version
    buf.extend(encode_string_utf8("play"));      // protocol
    buf.extend(encode_var_int(0));               // channel count
    buf
}
```

## Order of Operations (Critical!)

1. Server sends `MinecraftRegisterPayload` (vanilla protocol, might be ignored)
2. **Server sends `c:version`** ← YOU MUST RESPOND TO THIS FIRST
3. **Client sends `c:version` response**
4. Server sends `c:register`
5. **Client sends `c:register` response**
6. Server may send other payloads (`neoforge:network`, `neoforge:register`)
7. Server sends `FinishConfiguration` to transition to play phase

If you skip step 2 or 3, the server treats you as vanilla and disconnects.

## Testing

To verify your implementation:

1. Add debug logging to see when you receive each payload
2. Verify the bytes you're sending match the expected format
3. Test against a NeoForge 21.1 server
4. Check server logs for the specific error to confirm negotiation is occurring

## Expected Payload Hex Dumps

### Server sends c:version with [1]:
```
Payload ID: c:version
Data: 01
```

### Client responds with c:version [1]:
```
Payload ID: c:version
Data: 01
```

### Server sends c:register (example with no channels):
```
Payload ID: c:register
Data: 01 04 70 6c 61 79 00
       ^  ^ ^^^^^^^^^^^^^^ ^
       |  |       |        |
       |  |       |        +-- channel count = 0
       |  |       +---------- "play" (UTF-8 encoded)
       |  +------------------ length of "play" (4 bytes)
       +-------------------- version = 1
```

### Client responds with c:register:
```
Payload ID: c:register
Data: 01 04 70 6c 61 79 00
(Same as above - your empty response)
```

## Common Mistakes

1. **Not responding to `c:version` fast enough** - The server expects this first
2. **Wrong identifier format** - Use exactly `c:version` and `c:register`, not `neoforge:...`
3. **Not sending back the right protocol name** - Must be `play` not `Play` or other variants
4. **Forgetting to send both payloads** - Both `c:version` AND `c:register` are required
5. **Sending modded payloads before negotiation** - Only send after both handshakes complete

## References

- CommonVersionPayload: `/home/bmerriam/neoforge-repo/src/main/java/net/neoforged/neoforge/network/payload/CommonVersionPayload.java`
- CommonRegisterPayload: `/home/bmerriam/neoforge-repo/src/main/java/net/neoforged/neoforge/network/payload/CommonRegisterPayload.java`
- NetworkRegistry: `/home/bmerriam/neoforge-repo/src/main/java/net/neoforged/neoforge/network/registration/NetworkRegistry.java` (lines 342-416)
- Full analysis: See `neoforge_analysis.md` and `neoforge_packet_format.md`
