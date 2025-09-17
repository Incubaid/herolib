module heroserver

import time

// Active session data
pub struct Session {
pub mut:
	session_key string
	pubkey string
	created_at time.Time
	last_activity time.Time
	expires_at time.Time
}