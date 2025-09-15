#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.crypt
import freeflowuniverse.herolib.core.redisclient

// Connect to default Redis instance (127.0.0.1:6379)
mut age_client := crypt.new_age_client()!

// Test stateless encryption
println('Testing stateless encryption...')
keypair := age_client.generate_keypair() or {
	println('Error generating keypair: ${err}')
	return
}

message := 'Hello, AGE encryption!'
encrypted := age_client.encrypt(keypair.recipient, message) or {
	println('Error encrypting message: ${err}')
	return
}

decrypted := age_client.decrypt(keypair.identity, encrypted.ciphertext) or {
	println('Error decrypting message: ${err}')
	return
}

println('Original message: ${message}')
println('Encrypted message: ${encrypted.ciphertext}')
println('Decrypted message: ${decrypted}')

assert decrypted == message
println('Stateless encryption test passed!')

// Test stateless signing
println('\nTesting stateless signing...')
signing_keypair := age_client.generate_signing_keypair() or {
	println('Error generating signing keypair: ${err}')
	return
}

signed := age_client.sign(signing_keypair.sign_key, message) or {
	println('Error signing message: ${err}')
	return
}

verified := age_client.verify(signing_keypair.verify_key, message, signed.signature) or {
	println('Error verifying signature: ${err}')
	return
}
println('Message: ${message}')
println('Signature: ${signed.signature}')
println('Signature valid: ${verified}')

assert verified == true
println('Stateless signing test passed!')

// Test key-managed encryption
println('\nTesting key-managed encryption...')
key_name := 'example_encryption_key'
named_keypair := age_client.create_named_keypair(key_name) or {
	println('Error creating named keypair: ${err}')
	return
}

named_encrypted := age_client.encrypt_with_named_key(key_name, message) or {
	println('Error encrypting with named key: ${err}')
	return
}

named_decrypted := age_client.decrypt_with_named_key(key_name, named_encrypted.ciphertext) or {
	println('Error decrypting with named key: ${err}')
	return
}
println('Key name: ${key_name}')
println('Encrypted with named key: ${named_encrypted.ciphertext}')
println('Decrypted with named key: ${named_decrypted}')

assert named_decrypted == message
println('Key-managed encryption test passed!')

// Test key-managed signing
println('\nTesting key-managed signing...')
signing_key_name := 'example_signing_key'
age_client.create_named_signing_keypair(signing_key_name) or {
	println('Error creating named signing keypair: ${err}')
	return
}

named_signed := age_client.sign_with_named_key(signing_key_name, message) or {
	println('Error signing with named key: ${err}')
	return
}

named_verified := age_client.verify_with_named_key(signing_key_name, message, named_signed.signature) or {
	println('Error verifying with named key: ${err}')
	return
}
println('Signing key name: ${signing_key_name}')
println('Signature: ${named_signed.signature}')
println('Signature valid: ${named_verified}')

assert named_verified == true
println('Key-managed signing test passed!')

// Test list keys
println('\nTesting list keys...')
keys := age_client.list_keys() or {
	println('Error listing keys: ${err}')
	return
}
println('Stored keys: ${keys}')
println('All tests completed successfully!')
