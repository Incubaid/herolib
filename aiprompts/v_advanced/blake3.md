
## `crypto.blake3` Module


```v
fn sum256(data []u8) []u8
```

Returns the Blake3 256-bit hash of the provided data.

```v
fn sum_derive_key256(context []u8, key_material []u8) []u8
```

Computes the Blake3 256-bit derived-key hash based on the context and key material.

```v
fn sum_keyed256(data []u8, key []u8) []u8
```

Returns the Blake3 256-bit keyed hash of the data using the specified key.

---

### Digest-Based API

```v
fn Digest.new_derive_key_hash(context []u8) !Digest
```

Initializes a `Digest` struct for creating a Blake3 derived‑key hash, using the provided context.

```v
fn Digest.new_hash() !Digest
```

Initializes a `Digest` struct for a standard (unkeyed) Blake3 hash.

```v
fn Digest.new_keyed_hash(key []u8) !Digest
```

Initializes a `Digest` struct for a keyed Blake3 hash, with the given key.

---

### `Digest` Methods

```v
fn (mut d Digest) write(data []u8) !
```

Feeds additional data bytes into the ongoing hash computation.

```v
fn (mut d Digest) checksum(size u64) []u8
```

Finalizes the hash and returns the resulting output.

* The `size` parameter specifies the number of output bytes—commonly `32` for a 256-bit digest, but can be up to `2**64`.

---

### Recommended Usage (in V)

```v
import crypto.blake3

mut hasher := crypto.blake3.Digest.new_hash() or { panic(err) }
hasher.write(data) or { panic(err) }
digest := hasher.checksum(24)  // returns a []u8 of length 24 (192 bits)
```
