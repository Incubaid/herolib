module utils

// Email pattern validator
pub fn is_valid_email(email string) bool {
	return email.contains('@') && email.contains('.')
}

// Phone number validator
pub fn is_valid_phone(phone string) bool {
	return phone.len >= 10
}

// ID validator
fn is_valid_id(id int) bool {
	return id > 0
}

// Check if string is alphanumeric
pub fn is_alphanumeric(text string) bool {
	for c in text {
		if !(c.is_alnum()) {
			return false
		}
	}
	return true
}
