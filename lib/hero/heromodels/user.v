module heromodels

import time
import crypto.blake3
import json

// User represents a person in the system
@[heap]
pub struct User {
pub mut:
	id         string // blake192 hash
	name       string
	email      string
	public_key string // for encryption/signing
	phone      string
	address    string
	avatar_url string
	bio        string
	timezone   string
	created_at i64
	updated_at i64
	status     UserStatus
}

pub enum UserStatus {
	active
	inactive
	suspended
	pending
}
