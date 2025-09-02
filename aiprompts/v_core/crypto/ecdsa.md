# module ecdsa


## Contents
- [generate_key](#generate_key)
- [new_key_from_seed](#new_key_from_seed)
- [privkey_from_string](#privkey_from_string)
- [pubkey_from_bytes](#pubkey_from_bytes)
- [pubkey_from_string](#pubkey_from_string)
- [PrivateKey.new](#PrivateKey.new)
- [HashConfig](#HashConfig)
- [Nid](#Nid)
- [C.BIO](#C.BIO)
- [CurveOptions](#CurveOptions)
- [PrivateKey](#PrivateKey)
  - [sign](#sign)
  - [sign_with_options](#sign_with_options)
  - [bytes](#bytes)
  - [seed](#seed)
  - [public_key](#public_key)
  - [equal](#equal)
  - [free](#free)
- [PublicKey](#PublicKey)
  - [bytes](#bytes)
  - [equal](#equal)
  - [free](#free)
  - [verify](#verify)
- [SignerOpts](#SignerOpts)

## generate_key
```v
fn generate_key(opt CurveOptions) !(PublicKey, PrivateKey)
```

generate_key generates a new key pair. If opt was not provided, its default to prime256v1 curve. If you want another curve, use `pubkey, pivkey := ecdsa.generate_key(nid: .secp384r1)!` instead.

[[Return to contents]](#Contents)

## new_key_from_seed
```v
fn new_key_from_seed(seed []u8, opt CurveOptions) !PrivateKey
```

new_key_from_seed creates a new private key from the seed bytes. If opt was not provided, its default to prime256v1 curve.

Notes on the seed:

You should make sure, the seed bytes come from a cryptographically secure random generator, likes the `crypto.rand` or other trusted sources. Internally, the seed size's would be checked to not exceed the key size of underlying curve, ie, 32 bytes length for p-256 and secp256k1, 48 bytes length for p-384 and 66 bytes length for p-521. Its recommended to use seed with bytes length matching with underlying curve key size.

[[Return to contents]](#Contents)

## privkey_from_string
```v
fn privkey_from_string(s string) !PrivateKey
```

privkey_from_string loads a PrivateKey from valid PEM-formatted string in s. Underlying wrapper support for old SECG and PKCS8 private key format, but this was not heavily tested. This routine does not support for the PKCS8 EncryptedPrivateKeyInfo format. See [ecdsa_seed_test.v](https://github.com/vlang/v/blob/master/vlib/crypto/ecdsa/example/ecdsa_seed_test.v) file for example of usage.

[[Return to contents]](#Contents)

## pubkey_from_bytes
```v
fn pubkey_from_bytes(bytes []u8) !PublicKey
```

pubkey_from_bytes loads ECDSA Public Key from bytes array. The bytes of data should be a valid of ASN.1 DER serialized SubjectPublicKeyInfo structrue of RFC 5480. Otherwise, its should an error. Typically, you can load the bytes from pem formatted of ecdsa public key.

Examples:
```codeblock
import crypto.pem
import crypto.ecdsa

const pubkey_sample = '-----BEGIN PUBLIC KEY-----
MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE+P3rhFkT1fXHYbY3CpcBdh6xTC74MQFx
cftNVD3zEPVzo//OalIVatY162ksg8uRWBdvFFuHZ9OMVXkbjwWwhcXP7qmI9rOS
LR3AGUldy+bBpV2nT306qCIwgUAMeOJP
-----END PUBLIC KEY-----'

block, _ := pem.decode(pubkey_sample) or { panic(err) }
pubkey := ecdsa.pubkey_from_bytes(block.data)!
```


[[Return to contents]](#Contents)

## pubkey_from_string
```v
fn pubkey_from_string(s string) !PublicKey
```

pubkey_from_string loads a PublicKey from valid PEM-formatted string in s.

[[Return to contents]](#Contents)

## PrivateKey.new
```v
fn PrivateKey.new(opt CurveOptions) !PrivateKey
```

PrivateKey.new creates a new key pair. By default, it would create a prime256v1 based key. Dont forget to call `.free()` after finish with your key.

[[Return to contents]](#Contents)

## HashConfig
```v
enum HashConfig {
	with_recommended_hash
	with_no_hash
	with_custom_hash
}
```

HashConfig is an enumeration of the possible options for key signing (verifying).

[[Return to contents]](#Contents)

## Nid
```v
enum Nid {
	prime256v1 = C.NID_X9_62_prime256v1
	secp384r1  = C.NID_secp384r1
	secp521r1  = C.NID_secp521r1
	secp256k1  = C.NID_secp256k1
}
```

Nid is an enumeration of the supported curves

[[Return to contents]](#Contents)

## C.BIO
```v
struct C.BIO {}
```

[[Return to contents]](#Contents)

## CurveOptions
```v
struct CurveOptions {
pub mut:
	// default to NIST P-256 curve
	nid Nid = .prime256v1
	// by default, allow arbitrary size of seed bytes as key.
	// Set it to `true` when you need fixed size, using the curve key size.
	// Its main purposes is to support the `.new_key_from_seed` call.
	fixed_size bool
}
```

CurveOptions represents configuration options to drive keypair generation.

[[Return to contents]](#Contents)

## PrivateKey
```v
struct PrivateKey {
	// The new high level of keypair opaque
	evpkey &C.EVP_PKEY
mut:
	// ks_flag with .flexible value allowing
	// flexible-size seed bytes as key.
	// When it is `.fixed`, it will use the underlying key size.
	ks_flag KeyFlag = .flexible
	// ks_size stores size of the seed bytes when ks_flag was .flexible.
	// You should set it to a non zero value
	ks_size int
}
```

PrivateKey represents ECDSA private key. Actually its a key pair, contains private key and public key parts.

[[Return to contents]](#Contents)

## sign
```v
fn (pv PrivateKey) sign(message []u8, opt SignerOpts) ![]u8
```

sign performs signing the message with the options. By default options, it will perform hashing before signing the message.

[[Return to contents]](#Contents)

## sign_with_options
```v
fn (pv PrivateKey) sign_with_options(message []u8, opt SignerOpts) ![]u8
```

sign_with_options signs message with the options. It will be deprecated, Use `PrivateKey.sign()` instead.

[[Return to contents]](#Contents)

## bytes
```v
fn (pv PrivateKey) bytes() ![]u8
```

bytes represent private key as bytes.

[[Return to contents]](#Contents)

## seed
```v
fn (pv PrivateKey) seed() ![]u8
```

seed gets the seed (private key bytes). It will be deprecated. Use `PrivateKey.bytes()` instead.

[[Return to contents]](#Contents)

## public_key
```v
fn (pv PrivateKey) public_key() !PublicKey
```

public_key gets the PublicKey from private key.

[[Return to contents]](#Contents)

## equal
```v
fn (priv_key PrivateKey) equal(other PrivateKey) bool
```

equal compares two private keys was equal.

[[Return to contents]](#Contents)

## free
```v
fn (pv &PrivateKey) free()
```

free clears out allocated memory for PrivateKey. Dont use PrivateKey after calling `.free()`

[[Return to contents]](#Contents)

## PublicKey
```v
struct PublicKey {
	// The new high level of keypair opaque
	evpkey &C.EVP_PKEY
}
```

PublicKey represents ECDSA public key for verifying message.

[[Return to contents]](#Contents)

## bytes
```v
fn (pbk PublicKey) bytes() ![]u8
```

bytes gets the bytes of public key.

[[Return to contents]](#Contents)

## equal
```v
fn (pub_key PublicKey) equal(other PublicKey) bool
```

equal compares two public keys was equal.

[[Return to contents]](#Contents)

## free
```v
fn (pb &PublicKey) free()
```

free clears out allocated memory for PublicKey. Dont use PublicKey after calling `.free()`

[[Return to contents]](#Contents)

## verify
```v
fn (pb PublicKey) verify(message []u8, sig []u8, opt SignerOpts) !bool
```

verify verifies a message with the signature are valid with public key provided . You should provide it with the same SignerOpts used with the `.sign()` call. or verify would fail (false).

[[Return to contents]](#Contents)

## SignerOpts
```v
struct SignerOpts {
pub mut:
	// default to .with_recommended_hash
	hash_config HashConfig = .with_recommended_hash
	// make sense when HashConfig != with_recommended_hash
	allow_smaller_size bool
	allow_custom_hash  bool
	// set to non-nil if allow_custom_hash was true
	custom_hash &hash.Hash = unsafe { nil }
}
```

SignerOpts represents configuration options to drive signing and verifying process.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
