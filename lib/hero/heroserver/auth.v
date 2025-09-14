module heroserver

import crypto.md5
import crypto.ed25519
import rand
import time

pub struct AuthConfig {
pub mut:
	// Add any authentication-related configuration here
	// For now, it can be empty or have default values
}

pub struct AuthManager {
mut:
    registered_keys map[string]string    // pubkey -> user_id
    pending_auths   map[string]AuthChallenge // challenge -> challenge_data
    active_sessions map[string]Session   // session_key -> session_data
}

pub struct AuthChallenge {
pub:
    pubkey     string
    challenge  string
    created_at i64
    expires_at i64
}

pub struct Session {
pub:
    user_id    string
    pubkey     string
    created_at i64
    expires_at i64
}

pub fn new_auth_manager(config AuthConfig) &AuthManager {
	// Use config if needed, for now it's just passed
	_ = config
    return &AuthManager{}
}

// Register public key
pub fn (mut am AuthManager) register_pubkey(pubkey string) !string {
    // Validate pubkey format
    if pubkey.len != 64 { // ed25519 pubkey length
        return error('Invalid public key format')
    }

    user_id := md5.hexhash(pubkey + time.now().unix().str())
    am.registered_keys[pubkey] = user_id
    return user_id
}

// Generate authentication challenge
pub fn (mut am AuthManager) create_auth_challenge(pubkey string) !string {
    // Check if pubkey is registered
    if pubkey !in am.registered_keys {
        return error('Public key not registered')
    }

    // Generate unique challenge
    random_data := rand.string(32)
    challenge := md5.hexhash(pubkey + random_data + time.now().unix().str())

    now := time.now().unix()
    am.pending_auths[challenge] = AuthChallenge{
        pubkey: pubkey
        challenge: challenge
        created_at: now
        expires_at: now + 300 // 5 minutes
    }

    return challenge
}

// Verify signature and create session
pub fn (mut am AuthManager) verify_and_create_session(challenge string, signature string) !string {
    // Get challenge data
    auth_challenge := am.pending_auths[challenge] or {
        return error('Invalid or expired challenge')
    }

    // Check expiration
    if time.now().unix() > auth_challenge.expires_at {
        am.pending_auths.delete(challenge)
        return error('Challenge expired')
    }

    // Verify signature
    pubkey_bytes := auth_challenge.pubkey.bytes()
    challenge_bytes := challenge.bytes()
    signature_bytes := signature.bytes()

    ed25519.verify(pubkey_bytes, challenge_bytes, signature_bytes) or {
        return error('Invalid signature')
    }

    // Create session
    session_key := md5.hexhash(auth_challenge.pubkey + time.now().unix().str() + rand.string(16))
    now := time.now().unix()

    am.active_sessions[session_key] = Session{
        user_id: am.registered_keys[auth_challenge.pubkey]
        pubkey: auth_challenge.pubkey
        created_at: now
        expires_at: now + 3600 // 1 hour
    }

    // Clean up challenge
    am.pending_auths.delete(challenge)

    return session_key
}

// Validate session
pub fn (am AuthManager) validate_session(session_key string) bool {
    session := am.active_sessions[session_key] or { return false }
    return time.now().unix() < session.expires_at
}