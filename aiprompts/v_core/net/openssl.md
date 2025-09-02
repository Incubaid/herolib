# module openssl


## Contents
- [new_ssl_conn](#new_ssl_conn)
- [C.BIO](#C.BIO)
- [C.SSL](#C.SSL)
- [C.SSL_CTX](#C.SSL_CTX)
- [C.SSL_METHOD](#C.SSL_METHOD)
- [C.X509](#C.X509)
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

## new_ssl_conn
```v
fn new_ssl_conn(config SSLConnectConfig) !&SSLConn
```

new_ssl_conn instance an new SSLCon struct

[[Return to contents]](#Contents)

## C.BIO
```v
struct C.BIO {
}
```

[[Return to contents]](#Contents)

## C.SSL
```v
struct C.SSL {
}
```

[[Return to contents]](#Contents)

## C.SSL_CTX
```v
struct C.SSL_CTX {
}
```

[[Return to contents]](#Contents)

## C.SSL_METHOD
```v
struct C.SSL_METHOD {
}
```

[[Return to contents]](#Contents)

## C.X509
```v
struct C.X509 {
}
```

[[Return to contents]](#Contents)

## SSLConn
```v
struct SSLConn {
pub:
	config SSLConnectConfig
pub mut:
	sslctx   &C.SSL_CTX = unsafe { nil }
	ssl      &C.SSL     = unsafe { nil }
	handle   int
	duration time.Duration

	owns_socket bool
}
```

SSLConn is the current connection

[[Return to contents]](#Contents)

## close
```v
fn (mut s SSLConn) close() !
```

close closes the ssl connection and does cleanup

[[Return to contents]](#Contents)

## shutdown
```v
fn (mut s SSLConn) shutdown() !
```

shutdown closes the ssl connection and does cleanup

[[Return to contents]](#Contents)

## connect
```v
fn (mut s SSLConn) connect(mut tcp_conn net.TcpConn, hostname string) !
```

connect to server using OpenSSL

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

[[Return to contents]](#Contents)

## read
```v
fn (mut s SSLConn) read(mut buffer []u8) !int
```

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
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
