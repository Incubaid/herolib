module crypt

// KeyPair represents an Age encryption key pair
pub struct KeyPair {
pub:
	recipient string // Public key (can be shared)
	identity  string // Private key (must be kept secret)
}

// SigningKeyPair represents an Age signing key pair
pub struct SigningKeyPair {
pub:
	verify_key string // Public verification key
	sign_key   string // Private signing key
}

// EncryptionResult represents the result of an encryption operation
pub struct EncryptionResult {
pub:
	ciphertext string // Base64-encoded encrypted data
}

// SignatureResult represents the result of a signing operation
pub struct SignatureResult {
pub:
	signature string // Base64-encoded signature
}
