# module mbedtls


## Contents
- [new_ssl_conn](#new_ssl_conn)
- [new_ssl_listener](#new_ssl_listener)
- [new_sslcerts](#new_sslcerts)
- [new_sslcerts_from_file](#new_sslcerts_from_file)
- [new_sslcerts_in_memory](#new_sslcerts_in_memory)
- [C.mbedtls_ctr_drbg_context](#C.mbedtls_ctr_drbg_context)
- [C.mbedtls_entropy_context](#C.mbedtls_entropy_context)
- [C.mbedtls_net_context](#C.mbedtls_net_context)
- [C.mbedtls_pk_context](#C.mbedtls_pk_context)
- [C.mbedtls_ssl_config](#C.mbedtls_ssl_config)
- [C.mbedtls_ssl_context](#C.mbedtls_ssl_context)
- [C.mbedtls_ssl_recv_t](#C.mbedtls_ssl_recv_t)
- [C.mbedtls_ssl_recv_timeout_t](#C.mbedtls_ssl_recv_timeout_t)
- [C.mbedtls_ssl_send_t](#C.mbedtls_ssl_send_t)
- [C.mbedtls_x509_crl](#C.mbedtls_x509_crl)
- [C.mbedtls_x509_crt](#C.mbedtls_x509_crt)
- [SSLCerts](#SSLCerts)
  - [cleanup](#cleanup)
- [SSLConn](#SSLConn)
  - [close](#close)
  - [shutdown](#shutdown)
  - [connect](#connect)
  - [dial](#dial)
  - [addr](#addr)
  - [peer_addr](#peer_addr)
  - [socket_read_into_ptr](#socket_read_into_ptr)
  - [read](#read)
  - [write_ptr](#write_ptr)
  - [write](#write)
  - [write_string](#write_string)
- [SSLConnectConfig](#SSLConnectConfig)
- [SSLListener](#SSLListener)
  - [shutdown](#shutdown)
  - [accept](#accept)

## new_ssl_conn
```v
fn new_ssl_conn(config SSLConnectConfig) !&SSLConn
```

new_ssl_conn returns a new SSLConn with the given config.

[[Return to contents]](#Contents)

## new_ssl_listener
```v
fn new_ssl_listener(saddr string, config SSLConnectConfig) !&SSLListener
```

create a new SSLListener binding to `saddr`

[[Return to contents]](#Contents)

## new_sslcerts
```v
fn new_sslcerts() &SSLCerts
```

new_sslcerts initializes and returns a pair of SSL certificates and key

[[Return to contents]](#Contents)

## new_sslcerts_from_file
```v
fn new_sslcerts_from_file(verify string, cert string, cert_key string) !&SSLCerts
```

new_sslcerts_from_file creates a new pair of SSL certificates, given their paths on the filesystem.

[[Return to contents]](#Contents)

## new_sslcerts_in_memory
```v
fn new_sslcerts_in_memory(verify string, cert string, cert_key string) !&SSLCerts
```

new_sslcerts_in_memory creates a pair of SSL certificates, given their contents (not paths).

[[Return to contents]](#Contents)

## C.mbedtls_ctr_drbg_context
```v
struct C.mbedtls_ctr_drbg_context {}
```

[[Return to contents]](#Contents)

## C.mbedtls_entropy_context
```v
struct C.mbedtls_entropy_context {}
```

[[Return to contents]](#Contents)

## C.mbedtls_net_context
```v
struct C.mbedtls_net_context {
mut:
	fd int
}
```

[[Return to contents]](#Contents)

## C.mbedtls_pk_context
```v
struct C.mbedtls_pk_context {}
```

[[Return to contents]](#Contents)

## C.mbedtls_ssl_config
```v
struct C.mbedtls_ssl_config {}
```

[[Return to contents]](#Contents)

## C.mbedtls_ssl_context
```v
struct C.mbedtls_ssl_context {}
```

[[Return to contents]](#Contents)

## C.mbedtls_ssl_recv_t
```v
struct C.mbedtls_ssl_recv_t {}
```

[[Return to contents]](#Contents)

## C.mbedtls_ssl_recv_timeout_t
```v
struct C.mbedtls_ssl_recv_timeout_t {}
```

[[Return to contents]](#Contents)

## C.mbedtls_ssl_send_t
```v
struct C.mbedtls_ssl_send_t {}
```

[[Return to contents]](#Contents)

## C.mbedtls_x509_crl
```v
struct C.mbedtls_x509_crl {}
```

[[Return to contents]](#Contents)

## C.mbedtls_x509_crt
```v
struct C.mbedtls_x509_crt {}
```

[[Return to contents]](#Contents)

## SSLCerts
```v
struct SSLCerts {
pub mut:
	cacert      C.mbedtls_x509_crt
	client_cert C.mbedtls_x509_crt
	client_key  C.mbedtls_pk_context
}
```

SSLCerts represents a pair of CA and client certificates + key

[[Return to contents]](#Contents)

## cleanup
```v
fn (mut c SSLCerts) cleanup()
```

cleanup frees the SSL certificates

[[Return to contents]](#Contents)

## SSLConn
```v
struct SSLConn {
pub:
	config SSLConnectConfig
pub mut:
	server_fd C.mbedtls_net_context
	ssl       C.mbedtls_ssl_context
	conf      C.mbedtls_ssl_config
	certs     &SSLCerts = unsafe { nil }
	handle    int
	duration  time.Duration
	opened    bool
	ip        string

	owns_socket bool
}
```

SSLConn is the current connection

[[Return to contents]](#Contents)

## close
```v
fn (mut s SSLConn) close() !
```

close terminates the ssl connection and does cleanup

[[Return to contents]](#Contents)

## shutdown
```v
fn (mut s SSLConn) shutdown() !
```

shutdown terminates the ssl connection and does cleanup

[[Return to contents]](#Contents)

## connect
```v
fn (mut s SSLConn) connect(mut tcp_conn net.TcpConn, hostname string) !
```

connect sets up an ssl connection on an existing TCP connection

[[Return to contents]](#Contents)

## dial
```v
fn (mut s SSLConn) dial(hostname string, port int) !
```

dial opens an ssl connection on hostname:port

[[Return to contents]](#Contents)

## addr
```v
fn (s &SSLConn) addr() !net.Addr
```

addr retrieves the local ip address and port number for this connection

[[Return to contents]](#Contents)

## peer_addr
```v
fn (s &SSLConn) peer_addr() !net.Addr
```

peer_addr retrieves the ip address and port number used by the peer

[[Return to contents]](#Contents)

## socket_read_into_ptr
```v
fn (mut s SSLConn) socket_read_into_ptr(buf_ptr &u8, len int) !int
```

socket_read_into_ptr reads `len` bytes into `buf`

[[Return to contents]](#Contents)

## read
```v
fn (mut s SSLConn) read(mut buffer []u8) !int
```

read reads data from the ssl connection into `buffer`

[[Return to contents]](#Contents)

## write_ptr
```v
fn (mut s SSLConn) write_ptr(bytes &u8, len int) !int
```

write_ptr writes `len` bytes from `bytes` to the ssl connection

[[Return to contents]](#Contents)

## write
```v
fn (mut s SSLConn) write(bytes []u8) !int
```

write writes data from `bytes` to the ssl connection

[[Return to contents]](#Contents)

## write_string
```v
fn (mut s SSLConn) write_string(str string) !int
```

write_string writes a string to the ssl connection

[[Return to contents]](#Contents)

## SSLConnectConfig
```v
struct SSLConnectConfig {
pub:
	verify   string // the path to a rootca.pem file, containing trusted CA certificate(s)
	cert     string // the path to a cert.pem file, containing client certificate(s) for the request
	cert_key string // the path to a key.pem file, containing private keys for the client certificate(s)
	validate bool   // set this to true, if you want to stop requests, when their certificates are found to be invalid

	in_memory_verification bool // if true, verify, cert, and cert_key are read from memory, not from a file

	get_certificate ?fn (mut SSLListener, string) !&SSLCerts
}
```

[[Return to contents]](#Contents)

## SSLListener
```v
struct SSLListener {
	saddr  string
	config SSLConnectConfig
mut:
	server_fd C.mbedtls_net_context
	ssl       C.mbedtls_ssl_context
	conf      C.mbedtls_ssl_config
	certs     &SSLCerts = unsafe { nil }
	opened    bool
	// handle		int
	// duration	time.Duration
}
```

SSLListener listens on a TCP port and accepts connection secured with TLS

[[Return to contents]](#Contents)

## shutdown
```v
fn (mut l SSLListener) shutdown() !
```

finish the listener and clean up resources

[[Return to contents]](#Contents)

## accept
```v
fn (mut l SSLListener) accept() !&SSLConn
```

accepts a new connection and returns a SSLConn of the connected client

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
