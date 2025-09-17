#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.crypt.herocrypt
import time

// Initialize the HeroCrypt client
// Assumes herodb is running on localhost:6381
mut client := herocrypt.new_default()!

println('HeroCrypt client initialized')

// -- Stateless (Ephemeral) Workflow --
println('\n--- Stateless (Ephemeral) Workflow ---')

// 1. Generate ephemeral encryption keypair
println('Generating ephemeral encryption keypair...')
enc_keypair := client.gen_enc_keypair()!
recipient_pub := enc_keypair[0]
identity_sec := enc_keypair[1]
println('  Recipient Public Key: ${recipient_pub[..30]}...')
println('  Identity Secret Key: ${identity_sec[..30]}...')

// 2. Encrypt a message
message := 'Hello, Stateless World!'
println('\nEncrypting message: "${message}"')
ciphertext := client.encrypt(recipient_pub, message)!
println('  Ciphertext: ${ciphertext[..30]}...')

// 3. Decrypt the message
println('\nDecrypting ciphertext...')
decrypted_message := client.decrypt(identity_sec, ciphertext)!
println('  Decrypted Message: ${decrypted_message}')
assert decrypted_message == message

// 4. Generate ephemeral signing keypair
println('\nGenerating ephemeral signing keypair...')
sign_keypair := client.gen_sign_keypair()!
verify_pub_b64 := sign_keypair[0]
sign_sec_b64 := sign_keypair[1]
println('  Verify Public Key (b64): ${verify_pub_b64[..30]}...')
println('  Sign Secret Key (b64): ${sign_sec_b64[..30]}...')

// 5. Sign a message
sign_message := 'This message is signed.'
println('\nSigning message: "${sign_message}"')
signature := client.sign(sign_sec_b64, sign_message)!
println('  Signature: ${signature[..30]}...')

// 6. Verify the signature
println('\nVerifying signature...')
is_valid := client.verify(verify_pub_b64, sign_message, signature)!
println('  Signature is valid: ${is_valid}')
assert is_valid

// -- Key-Managed (Persistent, Named) Workflow --
println('\n--- Key-Managed (Persistent, Named) Workflow ---')

// 1. Generate and persist a named encryption keypair
enc_key_name := 'my_app_enc_key'
println('\nGenerating and persisting named encryption keypair: "${enc_key_name}"')
client.keygen(enc_key_name)!

// 2. Encrypt a message by name
persistent_message := 'Hello, Persistent World!'
println('Encrypting message by name: "${persistent_message}"')
persistent_ciphertext := client.encrypt_by_name(enc_key_name, persistent_message)!
println('  Ciphertext: ${persistent_ciphertext[..30]}...')

// 3. Decrypt the message by name
println('Decrypting ciphertext by name...')
decrypted_persistent_message := client.decrypt_by_name(enc_key_name, persistent_ciphertext)!
println('  Decrypted Message: ${decrypted_persistent_message}')
assert decrypted_persistent_message == persistent_message

// 4. Generate and persist a named signing keypair
sign_key_name := 'my_app_sign_key'
println('\nGenerating and persisting named signing keypair: "${sign_key_name}"')
client.sign_keygen(sign_key_name)!

// 5. Sign a message by name
persistent_sign_message := 'This persistent message is signed.'
println('Signing message by name: "${persistent_sign_message}"')
persistent_signature := client.sign_by_name(sign_key_name, persistent_sign_message)!
println('  Signature: ${persistent_signature[..30]}...')

// 6. Verify the signature by name
println('Verifying signature by name...')
is_persistent_valid := client.verify_by_name(sign_key_name, persistent_sign_message, persistent_signature)!
println('  Signature is valid: ${is_persistent_valid}')
assert is_persistent_valid

// // 7. List all stored keys
// println('\n--- Listing Stored Keys ---')
// keys := client.list_keys()!
// println('Stored keys: ${keys}')

// // -- Clean up created keys --
// println('\n--- Cleaning up ---')
// client.redis_client.del('age:enc:${enc_key_name}')!
// client.redis_client.del('age:sign:${sign_key_name}')!
// println('Cleaned up persistent keys.')

println('\nHeroCrypt example finished successfully!')
