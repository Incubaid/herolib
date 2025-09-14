module crypt

import freeflowuniverse.herolib.core.redisclient

// Stateless AGE operations

// generate_keypair creates a new Age encryption key pair
pub fn (client &AGEClient) generate_keypair() !KeyPair {
	response := client.redis.send_expect_list(['AGE', 'GENENC'])!

	if response.len < 2 {
		return error('Invalid response from AGE GENENC command')
	}

	return KeyPair{
		recipient: response[0].str()
		identity:  response[1].str()
	}
}

// generate_signing_keypair creates a new Age signing key pair
pub fn (client &AGEClient) generate_signing_keypair() !SigningKeyPair {
	response := client.redis.send_expect_list(['AGE', 'GENSIGN'])!

	if response.len < 2 {
		return error('Invalid response from AGE GENSIGN command')
	}

	return SigningKeyPair{
		verify_key: response[0].str()
		sign_key:   response[1].str()
	}
}

// encrypt encrypts a message with the recipient's public key
pub fn (client &AGEClient) encrypt(recipient string, message string) !EncryptionResult {
	ciphertext := client.redis.send_expect_str(['AGE', 'ENCRYPT', recipient, message])!

	return EncryptionResult{
		ciphertext: ciphertext
	}
}

// decrypt decrypts a message with the identity (private key)
pub fn (client &AGEClient) decrypt(identity string, ciphertext string) !string {
	return client.redis.send_expect_str(['AGE', 'DECRYPT', identity, ciphertext])!
}

// sign signs a message with the signing key
pub fn (client &AGEClient) sign(sign_key string, message string) !SignatureResult {
	signature := client.redis.send_expect_str(['AGE', 'SIGN', sign_key, message])!

	return SignatureResult{
		signature: signature
	}
}

// verify verifies a signature with the verification key
pub fn (client &AGEClient) verify(verify_key string, message string, signature string) !bool {
	result := client.redis.send_expect_int(['AGE', 'VERIFY', verify_key, message, signature])!
	return result == 1
}

// Key-managed AGE operations

// create_named_keypair creates and stores a named encryption key pair
pub fn (client &AGEClient) create_named_keypair(name string) !KeyPair {
	response := client.redis.send_expect_list(['AGE', 'KEYGEN', name])!

	if response.len < 2 {
		return error('Invalid response from AGE KEYGEN command')
	}

	return KeyPair{
		recipient: response[0].str()
		identity:  response[1].str()
	}
}

// create_named_signing_keypair creates and stores a named signing key pair
pub fn (client &AGEClient) create_named_signing_keypair(name string) !SigningKeyPair {
	response := client.redis.send_expect_list(['AGE', 'SIGNKEYGEN', name])!

	if response.len < 2 {
		return error('Invalid response from AGE SIGNKEYGEN command')
	}

	return SigningKeyPair{
		verify_key: response[0].str()
		sign_key:   response[1].str()
	}
}

// encrypt_with_named_key encrypts a message using a named key
pub fn (client &AGEClient) encrypt_with_named_key(key_name string, message string) !EncryptionResult {
	ciphertext := client.redis.send_expect_str(['AGE', 'ENCRYPTNAME', key_name, message])!

	return EncryptionResult{
		ciphertext: ciphertext
	}
}

// decrypt_with_named_key decrypts a message using a named key
pub fn (client &AGEClient) decrypt_with_named_key(key_name string, ciphertext string) !string {
	return client.redis.send_expect_str(['AGE', 'DECRYPTNAME', key_name, ciphertext])!
}

// sign_with_named_key signs a message using a named signing key
pub fn (client &AGEClient) sign_with_named_key(key_name string, message string) !SignatureResult {
	signature := client.redis.send_expect_str(['AGE', 'SIGNNAME', key_name, message])!

	return SignatureResult{
		signature: signature
	}
}

// verify_with_named_key verifies a signature using a named verification key
pub fn (client &AGEClient) verify_with_named_key(key_name string, message string, signature string) !bool {
	result := client.redis.send_expect_int(['AGE', 'VERIFYNAME', key_name, message, signature])!
	return result == 1
}

// list_keys lists all stored AGE keys
pub fn (client &AGEClient) list_keys() ![]string {
	response := client.redis.send_expect_list(['AGE', 'LIST'])!

	mut keys := []string{}
	for i in 0 .. response.len {
		keys << response[i].str()
	}

	return keys
}
