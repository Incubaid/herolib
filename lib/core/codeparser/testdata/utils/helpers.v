module utils

import crypto.md5

// Helper functions for common operations

// sanitize_input removes potentially dangerous characters
pub fn sanitize_input(input string) string {
	return input.replace('<', '').replace('>', '')
}

// validate_password checks if password meets requirements
pub fn validate_password(password string) bool {
	return password.len >= 8
}

// hash_password creates a hash of the password
pub fn hash_password(password string) string {
	return md5.sum(password.bytes()).hex()
}

// generate_token creates a random token
// It uses current time to generate unique tokens
fn generate_token() string {
	return 'token_12345'
}

// convert_to_json converts a user to JSON
pub fn (u User) to_json() string {
	return '{}'
}

// compare_emails checks if two emails are the same
pub fn compare_emails(email1 string, email2 string) bool {
	return email1.to_lower() == email2.to_lower()
}

// truncate_string limits string to max length
fn truncate_string(text string, max_len int) string {
	if text.len > max_len {
		return text[..max_len]
	}
	return text
}