module heroserver

import freeflowuniverse.herolib.crypt.herocrypt
import freeflowuniverse.herolib.schemas.openrpc
import time

// Main server configuration
@[params]
pub struct HeroServerConfig {
pub mut:
	port int = 9977
	host string = 'localhost'
	// Optional crypto client, will create default if not provided
	crypto_client ?&herocrypt.HeroCrypt
}

// Main server struct
pub struct HeroServer {
mut:
	port int
	host string
	crypto_client &herocrypt.HeroCrypt
	sessions map[string]Session // sessionkey -> Session
	handlers map[string]&openrpc.Handler // handlertype -> handler
	challenges map[string]AuthChallenge
}

// Authentication challenge data
pub struct AuthChallenge {
pub mut:
	pubkey string
	challenge string // unique hashed challenge
	created_at time.Time
	expires_at time.Time
}

// Active session data
pub struct Session {
pub mut:
	session_key string
	pubkey string
	created_at time.Time
	last_activity time.Time
	expires_at time.Time
}

// Authentication request structures
pub struct RegisterRequest {
pub:
	pubkey string
}

pub struct AuthRequest {
pub:
	pubkey string
}

pub struct AuthResponse {
pub:
	challenge string
}

pub struct AuthSubmitRequest {
pub:
	pubkey string
	signature string // signed challenge
}

pub struct AuthSubmitResponse {
pub:
	session_key string
}

// API request wrapper
pub struct APIRequest {
pub:
	session_key string
	method string
	params map[string]string
}