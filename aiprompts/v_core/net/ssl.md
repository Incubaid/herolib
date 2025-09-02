# module ssl


## Contents
- [new_ssl_conn](#new_ssl_conn)
- [new_ssl_dialer](#new_ssl_dialer)
- [SSLConn](#SSLConn)
- [SSLConnectConfig](#SSLConnectConfig)
- [SSLDialer](#SSLDialer)
  - [dial](#dial)

## new_ssl_conn
```v
fn new_ssl_conn(config SSLConnectConfig) !&SSLConn
```

new_ssl_conn returns a new SSLConn with the given config.

[[Return to contents]](#Contents)

## new_ssl_dialer
```v
fn new_ssl_dialer(config SSLConnectConfig) net.Dialer
```

create_ssl_dialer creates a dialer that will initiate SSL secured connections.

[[Return to contents]](#Contents)

## SSLConn
```v
struct SSLConn {
	mbedtls.SSLConn
}
```

[[Return to contents]](#Contents)

## SSLConnectConfig
```v
struct SSLConnectConfig {
	mbedtls.SSLConnectConfig
}
```

[[Return to contents]](#Contents)

## SSLDialer
```v
struct SSLDialer {
	config SSLConnectConfig
}
```

SSLDialer is a concrete instance of the Dialer interface, for creating SSL socket connections.

[[Return to contents]](#Contents)

## dial
```v
fn (d SSLDialer) dial(address string) !net.Connection
```

dial initiates a new SSL connection.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
