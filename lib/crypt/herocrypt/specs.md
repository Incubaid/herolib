# HeroCrypt Technical Specifications

This document provides the low-level technical details for the HeroCrypt library, including the underlying Redis commands used to interact with HeroDB's AGE cryptography features.

## Communication Protocol

HeroCrypt communicates with HeroDB using the standard Redis protocol. All commands are sent as RESP (Redis Serialization Protocol) arrays.

## Stateless (Ephemeral) AGE Operations

These commands are used when the client manages its own keys.

### Encryption

-   **`AGE GENENC`**: Generates an ephemeral encryption keypair.
    -   **Returns**: An array containing the recipient (public key) and the identity (secret key).

-   **`AGE ENCRYPT <recipient> <message>`**: Encrypts a message using the recipient's public key.
    -   **`<recipient>`**: The public key (`age1...`).
    -   **`<message>`**: The plaintext message to encrypt.
    -   **Returns**: A base64-encoded ciphertext.

-   **`AGE DECRYPT <identity> <ciphertext>`**: Decrypts a ciphertext using the identity (secret key).
    -   **`<identity>`**: The secret key (`AGE-SECRET-KEY-1...`).
    -   **`<ciphertext>`**: The base64-encoded ciphertext.
    -   **Returns**: The decrypted plaintext message.

### Signing

-   **`AGE GENSIGN`**: Generates an ephemeral signing keypair.
    -   **Returns**: An array containing the public verification key (base64) and the secret signing key (base64).

-   **`AGE SIGN <sign_secret_b64> <message>`**: Signs a message with the secret key.
    -   **`<sign_secret_b64>`**: The base64-encoded secret signing key.
    -   **`<message>`**: The message to sign.
    -   **Returns**: A base64-encoded signature.

-   **`AGE VERIFY <verify_pub_b64> <message> <signature_b64>`**: Verifies a signature.
    -   **`<verify_pub_b64>`**: The base64-encoded public verification key.
    -   **`<message>`**: The original message.
    -   **`<signature_b64>`**: The base64-encoded signature.
    -   **Returns**: `1` if the signature is valid, `0` otherwise.

## Key-Managed (Persistent, Named) AGE Operations

These commands are used when HeroDB manages the keys.

### Encryption

-   **`AGE KEYGEN <name>`**: Generates and persists a named encryption keypair.
    -   **`<name>`**: A unique name for the key.
    -   **Returns**: An array containing the recipient and identity (for initial export, if needed).

-   **`AGE ENCRYPTNAME <name> <message>`**: Encrypts a message using a named key.
    -   **`<name>`**: The name of the stored key.
    -   **`<message>`**: The plaintext message.
    -   **Returns**: A base64-encoded ciphertext.

-   **`AGE DECRYPTNAME <name> <ciphertext>`**: Decrypts a ciphertext using a named key.
    -   **`<name>`**: The name of the stored key.
    -   **`<ciphertext>`**: The base64-encoded ciphertext.
    -   **Returns**: The decrypted plaintext message.

### Signing

-   **`AGE SIGNKEYGEN <name>`**: Generates and persists a named signing keypair.
    -   **`<name>`**: A unique name for the key.
    -   **Returns**: An array containing the public and secret keys (for initial export).

-   **`AGE SIGNNAME <name> <message>`**: Signs a message using a named key.
    -   **`<name>`**: The name of the stored key.
    -   **`<message>`**: The message to sign.
    -   **Returns**: A base64-encoded signature.

-   **`AGE VERIFYNAME <name> <message> <signature_b64>`**: Verifies a signature using a named key.
    -   **`<name>`**: The name of the stored key.
    -   **`<message>`**: The original message.
    -   **`<signature_b64>`**: The base64-encoded signature.
    -   **Returns**: `1` if the signature is valid, `0` otherwise.

### Key Listing

-   **`AGE LIST`**: Lists all stored AGE keys.
    -   **Returns**: An array of key names.