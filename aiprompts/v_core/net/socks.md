# module socks


## Contents
- [new_socks5_dialer](#new_socks5_dialer)
- [socks5_dial](#socks5_dial)
- [socks5_ssl_dial](#socks5_ssl_dial)
- [SOCKS5Dialer](#SOCKS5Dialer)
  - [dial](#dial)

## new_socks5_dialer
```v
fn new_socks5_dialer(base net.Dialer, proxy_address string, username string, password string) net.Dialer
```

new_socks5_dialer creates a dialer that will use a SOCKS5 proxy server to initiate connections. An underlying dialer is required to initiate the connection to the proxy server. Most users should use either net.default_tcp_dialer or ssl.create_ssl_dialer.

[[Return to contents]](#Contents)

## socks5_dial
```v
fn socks5_dial(proxy_url string, host string, username string, password string) !&net.TcpConn
```

socks5_dial create new instance of &net.TcpConn

[[Return to contents]](#Contents)

## socks5_ssl_dial
```v
fn socks5_ssl_dial(proxy_url string, host string, username string, password string) !&ssl.SSLConn
```

socks5_ssl_dial create new instance of &ssl.SSLConn

[[Return to contents]](#Contents)

## SOCKS5Dialer
```v
struct SOCKS5Dialer {
pub:
	dialer        net.Dialer
	proxy_address string
	username      string
	password      string
}
```

SOCKS5Dialer implements the Dialer interface initiating connections through a SOCKS5 proxy.

[[Return to contents]](#Contents)

## dial
```v
fn (sd SOCKS5Dialer) dial(address string) !net.Connection
```

dial initiates a new connection through the SOCKS5 proxy.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
