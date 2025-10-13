module dedupestor

import crypto.blake2b

pub const max_value_size = 1024 * 1024 // 1MB

// hash_data calculates the blake160 hash of the given data and returns it as a hex string.
pub fn hash_data(data []u8) string {
	return blake2b.sum160(data).hex()
}
