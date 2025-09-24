module crypt

fn test_stateless_encryption() {
	mut client := new_age_client()!

	// Generate a keypair
	keypair := client.generate_keypair()!

	// Encrypt a message
	message := 'Hello, AGE encryption!'
	encrypted := client.encrypt(keypair.recipient, message)!

	// Decrypt the message
	decrypted := client.decrypt(keypair.identity, encrypted.ciphertext)!

	assert decrypted == message
}

fn test_stateless_signing() {
	mut client := new_age_client()!

	// Generate a signing keypair
	keypair := client.generate_signing_keypair()!

	// Sign a message
	message := 'This message is signed'
	signed := client.sign(keypair.sign_key, message)!

	// Verify the signature
	verified := client.verify(keypair.verify_key, message, signed.signature)!

	assert verified == true
}

fn test_key_managed_encryption() {
	mut client := new_age_client()!

	// Create a named keypair
	key_name := 'test_encryption_key'
	client.create_named_keypair(key_name)!

	// Encrypt with the named key
	message := 'Hello, key-managed encryption!'
	encrypted := client.encrypt_with_named_key(key_name, message)!

	// Decrypt with the named key
	decrypted := client.decrypt_with_named_key(key_name, encrypted.ciphertext)!

	assert decrypted == message
}

fn test_key_managed_signing() {
	mut client := new_age_client()!

	// Create a named signing keypair
	key_name := 'test_signing_key'
	client.create_named_signing_keypair(key_name)!

	// Sign with the named key
	message := 'This message is signed with a named key'
	signed := client.sign_with_named_key(key_name, message)!

	// Verify with the named key
	verified := client.verify_with_named_key(key_name, message, signed.signature)!

	assert verified == true
}

fn test_list_keys() {
	mut client := new_age_client()!

	// Create some named keys
	client.create_named_keypair('list_test_key1')!
	client.create_named_signing_keypair('list_test_key2')!

	// List the keys
	keys := client.list_keys()!

	assert 'list_test_key1' in keys
	assert 'list_test_key2' in keys
}
