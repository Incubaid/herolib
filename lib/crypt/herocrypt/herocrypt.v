module herocrypt

import incubaid.herolib.core.redisclient

// HeroCrypt provides a client for HeroDB's AGE cryptography features.
pub struct HeroCrypt {
pub mut:
	redis_client &redisclient.Redis
}

// new returns a new HeroCrypt client
// url e.g. localhost:6381 (default)
// It pings the server to ensure a valid connection.
pub fn new(url_ string) !&HeroCrypt {
	mut url := url_
	if url == '' {
		url = 'localhost:6381'
	}
	mut redis := redisclient.new(url)!
	redis.ping()!
	return &HeroCrypt{
		redis_client: redis
	}
}

// new_default returns a new HeroCrypt client with the default URL.
pub fn new_default() !&HeroCrypt {
	return new('')
}

// -- Stateless (Ephemeral) Methods --

// gen_enc_keypair generates an ephemeral encryption keypair.
// Returns: [recipient_public_key, identity_secret_key]
pub fn (mut self HeroCrypt) gen_enc_keypair() ![]string {
	return self.redis_client.cmd_list_str('AGE', ['GENENC'])
}

// encrypt encrypts a message with a recipient public key.
pub fn (mut self HeroCrypt) encrypt(recipient_public_key string, message string) !string {
	return self.redis_client.cmd_str('AGE', ['ENCRYPT', recipient_public_key, message])
}

// decrypt decrypts a ciphertext with an identity secret key.
pub fn (mut self HeroCrypt) decrypt(identity_secret_key string, ciphertext_b64 string) !string {
	return self.redis_client.cmd_str('AGE', ['DECRYPT', identity_secret_key, ciphertext_b64])
}

// gen_sign_keypair generates an ephemeral signing keypair.
// Returns: [verify_public_key_b64, sign_secret_key_b64]
pub fn (mut self HeroCrypt) gen_sign_keypair() ![]string {
	return self.redis_client.cmd_list_str('AGE', ['GENSIGN'])
}

// sign signs a message with a signing secret key.
pub fn (mut self HeroCrypt) sign(sign_secret_key_b64 string, message string) !string {
	return self.redis_client.cmd_str('AGE', ['SIGN', sign_secret_key_b64, message])
}

// verify verifies a signature with a public verification key.
pub fn (mut self HeroCrypt) verify(verify_public_key_b64 string, message string, signature_b64 string) !bool {
	res := self.redis_client.cmd_str('AGE', ['VERIFY', verify_public_key_b64, message, signature_b64])!
	return res == '1'
}

// -- Key-Managed (Persistent, Named) Methods --

// keygen generates and persists a named encryption keypair.
pub fn (mut self HeroCrypt) keygen(name string) ![]string {
	return self.redis_client.cmd_list_str('AGE', ['KEYGEN', name])
}

// encrypt_by_name encrypts a message using a named key.
pub fn (mut self HeroCrypt) encrypt_by_name(name string, message string) !string {
	return self.redis_client.cmd_str('AGE', ['ENCRYPTNAME', name, message])
}

// decrypt_by_name decrypts a ciphertext using a named key.
pub fn (mut self HeroCrypt) decrypt_by_name(name string, ciphertext_b64 string) !string {
	return self.redis_client.cmd_str('AGE', ['DECRYPTNAME', name, ciphertext_b64])
}

// sign_keygen generates and persists a named signing keypair.
pub fn (mut self HeroCrypt) sign_keygen(name string) ![]string {
	return self.redis_client.cmd_list_str('AGE', ['SIGNKEYGEN', name])
}

// sign_by_name signs a message using a named signing key.
pub fn (mut self HeroCrypt) sign_by_name(name string, message string) !string {
	return self.redis_client.cmd_str('AGE', ['SIGNNAME', name, message])
}

// verify_by_name verifies a signature with a named verification key.
pub fn (mut self HeroCrypt) verify_by_name(name string, message string, signature_b64 string) !bool {
	res := self.redis_client.cmd_str('AGE', ['VERIFYNAME', name, message, signature_b64])!
	return res == '1'
}

// // list_keys lists all stored AGE keys.
// pub fn (mut self HeroCrypt) list_keys() ![]string {
// 	return self.redis_client.cmd_list_str('AGE', ['LIST'])
// }
