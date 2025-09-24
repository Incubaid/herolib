# module unix


## Contents
- [close](#close)
- [connect_stream](#connect_stream)
- [listen_stream](#listen_stream)
- [shutdown](#shutdown)
- [stream_socket_from_handle](#stream_socket_from_handle)
- [ListenOptions](#ListenOptions)
- [StreamConn](#StreamConn)
  - [addr](#addr)
  - [peer_addr](#peer_addr)
  - [close](#close)
  - [write_ptr](#write_ptr)
  - [write](#write)
  - [write_string](#write_string)
  - [read_ptr](#read_ptr)
  - [read](#read)
  - [read_deadline](#read_deadline)
  - [set_read_deadline](#set_read_deadline)
  - [write_deadline](#write_deadline)
  - [set_write_deadline](#set_write_deadline)
  - [read_timeout](#read_timeout)
  - [set_read_timeout](#set_read_timeout)
  - [write_timeout](#write_timeout)
  - [set_write_timeout](#set_write_timeout)
  - [wait_for_read](#wait_for_read)
  - [wait_for_write](#wait_for_write)
  - [str](#str)
- [StreamListener](#StreamListener)
  - [accept](#accept)
  - [accept_deadline](#accept_deadline)
  - [set_accept_deadline](#set_accept_deadline)
  - [accept_timeout](#accept_timeout)
  - [set_accept_timeout](#set_accept_timeout)
  - [wait_for_accept](#wait_for_accept)
  - [close](#close)
  - [unlink](#unlink)
  - [unlink_on_signal](#unlink_on_signal)
  - [addr](#addr)
- [StreamSocket](#StreamSocket)
  - [set_option_bool](#set_option_bool)
  - [set_option_int](#set_option_int)
- [UnixDialer](#UnixDialer)
  - [dial](#dial)

## close
```v
fn close(handle int) !
```

close a socket, given its file descriptor `handle`.

[[Return to contents]](#Contents)

## connect_stream
```v
fn connect_stream(socket_path string) !&StreamConn
```

connect_stream returns a SOCK_STREAM connection for an unix domain socket on `socket_path`

[[Return to contents]](#Contents)

## listen_stream
```v
fn listen_stream(socket_path string, options ListenOptions) !&StreamListener
```

listen_stream creates an unix domain socket at `socket_path`

[[Return to contents]](#Contents)

## shutdown
```v
fn shutdown(handle int, config net.ShutdownConfig) int
```

shutdown shutsdown a socket, given its file descriptor `handle`. By default it shuts it down in both directions, both for reading and for writing. You can change that using `net.shutdown(handle, how: .read)` or `net.shutdown(handle, how: .write)`

[[Return to contents]](#Contents)

## stream_socket_from_handle
```v
fn stream_socket_from_handle(sockfd int) !&StreamSocket
```

stream_socket_from_handle returns a `StreamSocket` instance from the raw file descriptor `sockfd`

[[Return to contents]](#Contents)

## ListenOptions
```v
struct ListenOptions {
pub:
	backlog int = 128
}
```

[[Return to contents]](#Contents)

## StreamConn
```v
struct StreamConn {
pub mut:
	sock StreamSocket
mut:
	handle         int
	write_deadline time.Time
	read_deadline  time.Time
	read_timeout   time.Duration
	write_timeout  time.Duration
	is_blocking    bool
}
```

[[Return to contents]](#Contents)

## addr
```v
fn (c StreamConn) addr() !net.Addr
```

addr returns the local address of the stream

[[Return to contents]](#Contents)

## peer_addr
```v
fn (c StreamConn) peer_addr() !net.Addr
```

peer_addr returns the address of the remote peer of the stream

[[Return to contents]](#Contents)

## close
```v
fn (mut c StreamConn) close() !
```

close closes the connection

[[Return to contents]](#Contents)

## write_ptr
```v
fn (mut c StreamConn) write_ptr(b &u8, len int) !int
```

write_ptr blocks and attempts to write all data

[[Return to contents]](#Contents)

## write
```v
fn (mut c StreamConn) write(bytes []u8) !int
```

write blocks and attempts to write all data

[[Return to contents]](#Contents)

## write_string
```v
fn (mut c StreamConn) write_string(s string) !int
```

write_string blocks and attempts to write all data

[[Return to contents]](#Contents)

## read_ptr
```v
fn (mut c StreamConn) read_ptr(buf_ptr &u8, len int) !int
```

read_ptr attempts to write all data

[[Return to contents]](#Contents)

## read
```v
fn (mut c StreamConn) read(mut buf []u8) !int
```

read data into `buf`

[[Return to contents]](#Contents)

## read_deadline
```v
fn (mut c StreamConn) read_deadline() !time.Time
```

read_deadline returns the read deadline

[[Return to contents]](#Contents)

## set_read_deadline
```v
fn (mut c StreamConn) set_read_deadline(deadline time.Time)
```

set_read_deadlien sets the read deadline

[[Return to contents]](#Contents)

## write_deadline
```v
fn (mut c StreamConn) write_deadline() !time.Time
```

write_deadline returns the write deadline

[[Return to contents]](#Contents)

## set_write_deadline
```v
fn (mut c StreamConn) set_write_deadline(deadline time.Time)
```

set_write_deadline sets the write deadline

[[Return to contents]](#Contents)

## read_timeout
```v
fn (c &StreamConn) read_timeout() time.Duration
```

read_timeout returns the read timeout

[[Return to contents]](#Contents)

## set_read_timeout
```v
fn (mut c StreamConn) set_read_timeout(t time.Duration)
```

set_read_timeout sets the read timeout

[[Return to contents]](#Contents)

## write_timeout
```v
fn (c &StreamConn) write_timeout() time.Duration
```

write_timeout returns the write timeout

[[Return to contents]](#Contents)

## set_write_timeout
```v
fn (mut c StreamConn) set_write_timeout(t time.Duration)
```

set_write_timeout sets the write timeout

[[Return to contents]](#Contents)

## wait_for_read
```v
fn (mut c StreamConn) wait_for_read() !
```

wait_for_read blocks until the socket is ready to read

[[Return to contents]](#Contents)

## wait_for_write
```v
fn (mut c StreamConn) wait_for_write() !
```

wait_for_read blocks until the socket is ready to write

[[Return to contents]](#Contents)

## str
```v
fn (c StreamConn) str() string
```

str returns a string representation of connection `c`

[[Return to contents]](#Contents)

## StreamListener
```v
struct StreamListener {
pub mut:
	sock StreamSocket
mut:
	accept_timeout  time.Duration
	accept_deadline time.Time
}
```

[[Return to contents]](#Contents)

## accept
```v
fn (mut l StreamListener) accept() !&StreamConn
```

accept accepts blocks until a new connection occurs

[[Return to contents]](#Contents)

## accept_deadline
```v
fn (l &StreamListener) accept_deadline() !time.Time
```

accept_deadline returns the deadline until a new client is accepted

[[Return to contents]](#Contents)

## set_accept_deadline
```v
fn (mut l StreamListener) set_accept_deadline(deadline time.Time)
```

set_accept_deadline sets the deadlinme until a new client is accepted

[[Return to contents]](#Contents)

## accept_timeout
```v
fn (l &StreamListener) accept_timeout() time.Duration
```

accept_timeout returns the timeout until a new client is accepted

[[Return to contents]](#Contents)

## set_accept_timeout
```v
fn (mut l StreamListener) set_accept_timeout(t time.Duration)
```

set_accept_timeout sets the timeout until a new client is accepted

[[Return to contents]](#Contents)

## wait_for_accept
```v
fn (mut l StreamListener) wait_for_accept() !
```

wait_for_accept blocks until a client can be accepted

[[Return to contents]](#Contents)

## close
```v
fn (mut l StreamListener) close() !
```

close closes the listening socket and unlinks/removes the socket file

[[Return to contents]](#Contents)

## unlink
```v
fn (mut l StreamListener) unlink() !
```

unlink removes the unix socket from the file system

[[Return to contents]](#Contents)

## unlink_on_signal
```v
fn (mut l StreamListener) unlink_on_signal(signum os.Signal) !
```

unlink_on_signal removes the socket from the filesystem when signal `signum` occurs

[[Return to contents]](#Contents)

## addr
```v
fn (mut l StreamListener) addr() !net.Addr
```

addr returns the `net.Addr` version of the listening socket's path

[[Return to contents]](#Contents)

## StreamSocket
```v
struct StreamSocket {
	net.Socket
mut:
	socket_path string
}
```

[[Return to contents]](#Contents)

## set_option_bool
```v
fn (mut s StreamSocket) set_option_bool(opt net.SocketOption, value bool) !
```

set_option_bool sets a boolean option on the socket

[[Return to contents]](#Contents)

## set_option_int
```v
fn (mut s StreamSocket) set_option_int(opt net.SocketOption, value int) !
```

set_option_bool sets an int option on the socket

[[Return to contents]](#Contents)

## UnixDialer
```v
struct UnixDialer {}
```

UnixDialer is a concrete instance of the Dialer interface, for creating unix socket connections.

[[Return to contents]](#Contents)

## dial
```v
fn (u UnixDialer) dial(address string) !net.Connection
```

dial will try to create a new abstract connection to the given address. It will return an error, if that is not possible.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
