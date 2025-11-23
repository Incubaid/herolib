module testdata

import time
import os

const (
	app_version = '1.0.0'
	max_users = 1000
	default_timeout = 30
)

// User represents an application user
// It stores all information related to a user
// including contact and status information
pub struct User {
pub:
	id       int
	email    string
	username string
pub mut:
	active   bool
	created  string
	updated  string
}

// Profile represents user profile information
pub struct Profile {
pub:
	user_id int
	bio     string
	avatar  string
mut:
	followers int
	following int
pub mut:
	verified  bool
}

// Settings represents user settings
struct Settings {
pub:
	theme_dark bool
	language   string
mut:
	notifications_enabled bool
}

struct InternalConfig {
	debug    bool
	log_level int
}