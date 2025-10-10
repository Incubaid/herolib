# HeroCrypt: Effortless Cryptography with HeroDB

HeroCrypt is a library that provides a simple and secure way to handle encryption and digital signatures by leveraging the power of [HeroDB](https://git.ourworld.tf/herocode/herodb). It abstracts the underlying complexity of cryptographic operations, allowing you to secure your application's data with minimal effort.

## What is HeroDB?

HeroDB is a high-performance, Redis-compatible database that offers built-in support for advanced cryptographic operations using the [AGE encryption format](https://age-encryption.org/). This integration makes it an ideal backend for applications requiring robust, end-to-end security.

## Core Features of HeroCrypt

- **Encryption & Decryption**: Securely encrypt and decrypt data.
- **Digital Signatures**: Sign and verify messages to ensure their integrity and authenticity.
- **Flexible Key Management**: Choose between two modes for managing your cryptographic keys:
    1.  **Key-Managed (Server-Side)**: Let HeroDB manage your keys. Keys are stored securely within the database and are referenced by a name. This is the recommended approach for simplicity and centralized key management.
    2.  **Stateless (Client-Side)**: Manage your own keys on the client side. You pass the key material with every cryptographic operation. This mode is for advanced users who require full control over their keys.


## To start a db see

https://git.ourworld.tf/herocode/herodb

to do:

```bash
hero git pull https://git.ourworld.tf/herocode/herodb
~/code/git.ourworld.tf/herocode/herodb/run.sh
```

## Key-Managed Mode (Recommended)

In this mode, HeroDB generates and stores the keypairs for you. You only need to provide a name for your key.

### Encryption

```v
import freeflowuniverse.herolib.crypt.herocrypt

mut client := herocrypt.new_default()!

// Generate and persist a named encryption keypair
client.keygen('my_app_key')!

// Encrypt a message
message := 'This is a secret message.'
ciphertext := client.encrypt_by_name('my_app_key', message)!

// Decrypt the message
decrypted_message := client.decrypt_by_name('my_app_key', ciphertext)!
assert decrypted_message == message
```

### Signing

```v
import freeflowuniverse.herolib.crypt.herocrypt

mut client := herocrypt.new_default()!

// Generate and persist a named signing keypair
client.sign_keygen('my_signer_key')!

// Sign a message
message := 'This message needs to be signed.'
signature := client.sign_by_name('my_signer_key', message)!

// Verify the signature
is_valid := client.verify_by_name('my_signer_key', message, signature)!
assert is_valid
```

## Stateless Mode (Advanced)

In this mode, you are responsible for generating and managing your own keys.

### Encryption

```v
import freeflowuniverse.herolib.crypt.herocrypt

mut client := herocrypt.new_default()!

// Generate an ephemeral encryption keypair
keypair := client.gen_enc_keypair()!
recipient_pub := keypair[0]
identity_sec := keypair[1]

// Encrypt a message
message := 'This is a secret message.'
ciphertext := client.encrypt(recipient_pub, message)!

// Decrypt the message
decrypted_message := client.decrypt(identity_sec, ciphertext)!
assert decrypted_message == message
```

### Signing

```v
import freeflowuniverse.herolib.crypt.herocrypt

mut client := herocrypt.new_default()!

// Generate an ephemeral signing keypair
keypair := client.gen_sign_keypair()!
verify_pub_b64 := keypair[0]
sign_sec_b64 := keypair[1]

// Sign a message
message := 'This message needs to be signed.'
signature := client.sign(sign_sec_b64, message)!

// Verify the signature
is_valid := client.verify(verify_pub_b64, message, signature)!
assert is_valid

```