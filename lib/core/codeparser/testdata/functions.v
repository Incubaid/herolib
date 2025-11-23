module testdata

import time
import json

// create_user creates a new user in the system
// Arguments:
//   email: user email address
//   username: unique username
// Returns: the created User or error
pub fn create_user(email string, username string) !User {
	if email == '' {
		return error('email cannot be empty')
	}
	if username == '' {
		return error('username cannot be empty')
	}
	return User{
		id: 1
		email: email
		username: username
		active: true
		created: time.now().str()
		updated: time.now().str()
	}
}

// get_user retrieves a user by ID
pub fn get_user(user_id int) ?User {
	if user_id <= 0 {
		return none
	}
	return User{
		id: user_id
		email: 'user_${user_id}@example.com'
		username: 'user_${user_id}'
		active: true
		created: '2024-01-01'
		updated: '2024-01-01'
	}
}

// delete_user deletes a user from the system
pub fn delete_user(user_id int) ! {
	if user_id <= 0 {
		return error('invalid user id')
	}
}

// Internal helper for validation
fn validate_email(email string) bool {
	return email.contains('@')
}

// Process multiple users
fn batch_create_users(emails []string) ![]User {
	mut users := []User{}
	for email in emails {
		user_name := email.split('@')[0]
		user := create_user(email, user_name)!
		users << user
	}
	return users
}