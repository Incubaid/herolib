# HeroDB AGE Encryption (hero.crypt)

This module provides client-side access to HeroDB's AGE encryption features, offering two distinct modes of operation:

- **Stateless Mode**: Client manages keys, nothing stored on server
- **Key-Managed Mode**: Server stores named keys

## Installation

Ensure HeroDB is running with encryption enabled:

```bash
herodb --dir /path/to/data --port 6379 --encrypt --encryption-key yoursecretkey
```

## Usage

### Creating an AGE Client

```v
import freeflowuniverse.herolib.hero.crypt
import freeflowuniverse.herolib.core.redisclient

// Connect to default Redis instance (127.0.0.1:6379)
mut age_client := crypt.new_age_client()!

// Or connect to a specific Redis instance
mut age_client := crypt.new_age_client(
    redis_url: redisclient.RedisURL{
        address: 'my.herodb.server',
        port: 6379
    }
)!

// Or use an existing Redis client
mut redis := redisclient.core_get()!
mut age_client := crypt.new_age_client(
    redis: redis
)!
```

## Stateless Encryption (Client-Managed Keys)

In stateless mode, the client generates and manages keys. The server never stores any keys.

### Generate a Keypair

```v
// Generate a new encryption keypair
keypair := age_client.generate_keypair()!
println('Public key: ${keypair.recipient}')
println('Private key: ${keypair.identity}')

// Important: Store the identity (private key) securely!
```

### Encrypt and Decrypt

```v
// Encrypt a message with the public key
message := 'Hello, encrypted world!'
encrypted := age_client.encrypt(keypair.recipient, message)!
println('Encrypted: ${encrypted.ciphertext}')

// Decrypt with the private key
decrypted := age_client.decrypt(keypair.identity, encrypted.ciphertext)!
println('Decrypted: ${decrypted}')
```

### Signing and Verification

```v
// Generate a signing keypair
signing_keypair := age_client.generate_signing_keypair()!

// Sign a message
message := 'This message is authentic'
signed := age_client.sign(signing_keypair.sign_key, message)!
println('Signature: ${signed.signature}')

// Verify the signature
is_valid := age_client.verify(signing_keypair.verify_key, message, signed.signature)!
println('Signature valid: ${is_valid}')
```

## Key-Managed Encryption (Server-Stored Keys)

In key-managed mode, the server generates and stores named keys. Clients reference keys by name.

### Create Named Keys

```v
// Create a named encryption keypair
named_keypair := age_client.create_named_keypair('app1_encryption')!
println('Created encryption keypair: ${named_keypair.recipient}')

// Create a named signing keypair
named_signing_keypair := age_client.create_named_signing_keypair('app1_signing')!
println('Created signing keypair: ${named_signing_keypair.verify_key}')
```

### Encrypt and Decrypt with Named Keys

```v
// Encrypt with a named key
message := 'This message is encrypted with a named key'
encrypted := age_client.encrypt_with_named_key('app1_encryption', message)!
println('Encrypted: ${encrypted.ciphertext}')

// Decrypt with a named key
decrypted := age_client.decrypt_with_named_key('app1_encryption', encrypted.ciphertext)!
println('Decrypted: ${decrypted}')
```

### Sign and Verify with Named Keys

```v
// Sign with a named key
message := 'This message is signed with a named key'
signed := age_client.sign_with_named_key('app1_signing', message)!
println('Signature: ${signed.signature}')

// Verify with a named key
is_valid := age_client.verify_with_named_key('app1_signing', message, signed.signature)!
println('Signature valid: ${is_valid}')
```

### List Stored Keys

```v
// List all stored keys
keys := age_client.list_keys()!
println('Stored keys: ${keys}')
```

## Choosing Between Modes

### Use Stateless Mode When:

- You want complete control over key management
- You don't want the server to store any private keys
- You need to use the same keys across multiple servers

### Use Key-Managed Mode When:

- You want simpler client code (no need to manage keys)
- You trust the server to securely store private keys
- You need centralized key management with rotation options

## Security Considerations

1. **Private Keys**: In stateless mode, you are responsible for securely storing private keys.
2. **Server Security**: In key-managed mode, ensure your HeroDB server is properly secured.
3. **Encryption at Rest**: HeroDB supports database-level encryption separate from AGE commands.
4. **Transport Security**: Consider using SSL/TLS to protect data in transit.

## Examples

### Secure Message Exchange

```v
// Sender (Alice)
mut alice_client := crypt.new_age_client()!
alice_keypair := alice_client.generate_keypair()!

// Bob gets Alice's public key (recipient)
mut bob_client := crypt.new_age_client()!
bob_message := 'Secret message for Alice'
encrypted := bob_client.encrypt(alice_keypair.recipient, bob_message)!

// Alice decrypts Bob's message
decrypted := alice_client.decrypt(alice_keypair.identity, encrypted.ciphertext)!
assert decrypted == bob_message
```

### Document Signing

```v
// Author
mut author_client := crypt.new_age_client()!
author_keypair := author_client.create_named_signing_keypair('document_author')!
document := 'This is an official document'
signature := author_client.sign_with_named_key('document_author', document)!

// Verifier
mut verifier_client := crypt.new_age_client()!
is_authentic := verifier_client.verify_with_named_key('document_author', document, signature.signature)!
