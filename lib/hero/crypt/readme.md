# HeroDB AGE Encryption (hero.crypt)

This module provides client-side access to HeroDB's AGE encryption features, offering two distinct modes of operation:

- **Stateless Mode**: Client manages keys, nothing stored on server
- **Key-Managed Mode**: Server stores named keys

## Installation

Ensure HeroDB is running with encryption enabled:

```bash
herodb --dir /path/to/data --port 6381 --encrypt --encryption-key yoursecretkey
```

## To start a db see

https://git.ourworld.tf/herocode/herodb

to do:

```bash
hero git pull https://git.ourworld.tf/herocode/herodb
~/code/git.ourworld.tf/herocode/herodb/run.sh
```

## Usage

### Creating an AGE Client

```v
import freeflowuniverse.herolib.crypt.herocrypt

// Connect to default Redis instance (127.0.0.1:6381)
mut client := herocrypt.new_default()!
```

## Stateless Encryption (Client-Managed Keys)

In stateless mode, the client generates and manages keys. The server never stores any keys.

### Generate a Keypair

```v
// Generate a new encryption keypair
enc_keypair := client.gen_enc_keypair()!
recipient_pub := enc_keypair[0]
identity_sec := enc_keypair[1]
println('Public key: ${recipient_pub}')
println('Private key: ${identity_sec}')

// Important: Store the identity (private key) securely!
```

### Encrypt and Decrypt

```v
// Encrypt a message with the public key
message := 'Hello, encrypted world!'
ciphertext := client.encrypt(recipient_pub, message)!
println('Encrypted: ${ciphertext}')

// Decrypt with the private key
decrypted_message := client.decrypt(identity_sec, ciphertext)!
println('Decrypted: ${decrypted_message}')
```

### Signing and Verification

```v
// Generate a signing keypair
sign_keypair := client.gen_sign_keypair()!
verify_pub_b64 := sign_keypair[0]
sign_sec_b64 := sign_keypair[1]

// Sign a message
message := 'This message is authentic'
signature := client.sign(sign_sec_b64, message)!
println('Signature: ${signature}')

// Verify the signature
is_valid := client.verify(verify_pub_b64, message, signature)!
println('Signature valid: ${is_valid}')
```

## Key-Managed Encryption (Server-Stored Keys)

In key-managed mode, the server generates and stores named keys. Clients reference keys by name.

### Create Named Keys

```v
// Create a named encryption keypair
enc_key_name := 'app1_encryption'
client.keygen(enc_key_name)!
println('Created encryption keypair: "${enc_key_name}"')

// Create a named signing keypair
sign_key_name := 'app1_signing'
client.sign_keygen(sign_key_name)!
println('Created signing keypair: "${sign_key_name}"')
```

### Encrypt and Decrypt with Named Keys

```v
// Encrypt with a named key
message := 'This message is encrypted with a named key'
encrypted := client.encrypt_by_name('app1_encryption', message)!
println('Encrypted: ${encrypted}')

// Decrypt with a named key
decrypted := client.decrypt_by_name('app1_encryption', encrypted)!
println('Decrypted: ${decrypted}')
```

### Sign and Verify with Named Keys

```v
// Sign with a named key
message := 'This message is signed with a named key'
signature := client.sign_by_name('app1_signing', message)!
println('Signature: ${signature}')

// Verify with a named key
is_valid := client.verify_by_name('app1_signing', message, signature)!
println('Signature valid: ${is_valid}')
```

### List Stored Keys

```v
// List all stored keys
// keys := client.list_keys()!
// println('Stored keys: ${keys}')
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
```


