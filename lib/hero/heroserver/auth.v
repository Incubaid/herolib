module heroserver

import crypto.md5
import crypto.rand
import time
import encoding.base64

// Active challenges storage
mut challenges := map[string]AuthChallenge{}

// Register a public key (currently just validates format)
pub fn (mut server HeroServer) register(pubkey string) ! {
	// Validate public key format
	if pubkey.len < 10 {
		return error('Invalid public key format')
	}
	
	// For now, just return success
	// In future versions, could store registered keys
}

// Request authentication challenge
pub fn (mut server HeroServer) auth_request(pubkey string) !AuthResponse {
	// Generate random challenge data
	random_bytes := rand.bytes(32)!
	challenge_data := '${pubkey}:${random_bytes.hex()}:${time.now().unix}'
	
	// Create MD5 hash of challenge
	challenge := md5.hexhash(challenge_data)
	
	// Store challenge with expiration
	challenges[pubkey] = AuthChallenge{
		pubkey: pubkey
		challenge: challenge
		created_at: time.now()
		expires_at: time.now().add_seconds(300) // 5 minute expiry
	}
	
	return AuthResponse{
		challenge: challenge
	}
}

// Submit signed challenge for authentication
pub fn (mut server HeroServer) auth_submit(pubkey string, signature string) !AuthSubmitResponse {
	// Get stored challenge
	challenge_data := challenges[pubkey] or {
		return error('No active challenge for this public key')
	}
	
	// Check if challenge expired
	if time.now() > challenge_data.expires_at {
		challenges.delete(pubkey)
		return error('Challenge expired')
	}
	
	// Verify signature using HeroCrypt
	// Note: We need the verification key, which should be derived from pubkey
	// For now, assume pubkey is the verification key in correct format
	is_valid := server.crypto_client.verify(pubkey, challenge_data.challenge, signature)!
	
	if !is_valid {
		return error('Invalid signature')
	}
	
	// Generate session key
	session_data := '${pubkey}:${time.now().unix}:${rand.bytes(16)!.hex()}'
	session_key := md5.hexhash(session_data)
	
	// Create session
	session := Session{
		session_key: session_key
		pubkey: pubkey
		created_at: time.now()
		last_activity: time.now()
		expires_at: time.now().add_seconds(3600 * 24) // 24 hour session
	}
	
	// Store session
	server.sessions[session_key] = session
	
	// Clean up challenge
	challenges.delete(pubkey)
	
	return AuthSubmitResponse{
		session_key: session_key
	}
}

// Validate session key
pub fn (mut server HeroServer) validate_session(session_key string) !Session {
	mut session := server.sessions[session_key] or {
		return error('Invalid session key')
	}
	
	// Check if session expired
	if time.now() > session.expires_at {
		server.sessions.delete(session_key)
		return error('Session expired')
	}
	
	// Update last activity
	session.last_activity = time.now()
	server.sessions[session_key] = session
	
	return session
}