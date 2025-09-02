# module net


## Contents
- [Constants](#Constants)
- [addr_from_socket_handle](#addr_from_socket_handle)
- [close](#close)
- [default_tcp_dialer](#default_tcp_dialer)
- [dial_tcp](#dial_tcp)
- [dial_tcp_with_bind](#dial_tcp_with_bind)
- [dial_udp](#dial_udp)
- [error_code](#error_code)
- [listen_tcp](#listen_tcp)
- [listen_udp](#listen_udp)
- [new_ip](#new_ip)
- [new_ip6](#new_ip6)
- [new_tcp_socket](#new_tcp_socket)
- [peer_addr_from_socket_handle](#peer_addr_from_socket_handle)
- [resolve_addrs](#resolve_addrs)
- [resolve_addrs_fuzzy](#resolve_addrs_fuzzy)
- [resolve_ipaddrs](#resolve_ipaddrs)
- [set_blocking](#set_blocking)
- [shutdown](#shutdown)
- [socket_error](#socket_error)
- [socket_error_message](#socket_error_message)
- [split_address](#split_address)
- [tcp_socket_from_handle_raw](#tcp_socket_from_handle_raw)
- [validate_port](#validate_port)
- [wrap_error](#wrap_error)
- [Connection](#Connection)
- [Dialer](#Dialer)
- [TcpSocket](#TcpSocket)
  - [set_option_bool](#set_option_bool)
  - [set_option_int](#set_option_int)
  - [set_dualstack](#set_dualstack)
  - [bind](#bind)
- [UdpSocket](#UdpSocket)
  - [set_option_bool](#set_option_bool)
  - [set_dualstack](#set_dualstack)
  - [close](#close)
  - [select](#select)
  - [remote](#remote)
- [AddrFamily](#AddrFamily)
- [ShutdownDirection](#ShutdownDirection)
- [SocketOption](#SocketOption)
- [SocketType](#SocketType)
- [Addr](#Addr)
  - [family](#family)
  - [len](#len)
  - [port](#port)
  - [str](#str)
- [C.addrinfo](#C.addrinfo)
- [C.fd_set](#C.fd_set)
- [C.sockaddr_in](#C.sockaddr_in)
- [C.sockaddr_in6](#C.sockaddr_in6)
- [C.sockaddr_un](#C.sockaddr_un)
- [Ip](#Ip)
  - [str](#str)
- [Ip6](#Ip6)
  - [str](#str)
- [ListenOptions](#ListenOptions)
- [ShutdownConfig](#ShutdownConfig)
- [Socket](#Socket)
  - [address](#address)
- [TCPDialer](#TCPDialer)
  - [dial](#dial)
- [TcpConn](#TcpConn)
  - [addr](#addr)
  - [close](#close)
  - [get_blocking](#get_blocking)
  - [peer_addr](#peer_addr)
  - [peer_ip](#peer_ip)
  - [read](#read)
  - [read_deadline](#read_deadline)
  - [read_line](#read_line)
  - [read_line_max](#read_line_max)
  - [read_ptr](#read_ptr)
  - [read_timeout](#read_timeout)
  - [set_blocking](#set_blocking)
  - [set_read_deadline](#set_read_deadline)
  - [set_read_timeout](#set_read_timeout)
  - [set_sock](#set_sock)
  - [set_write_deadline](#set_write_deadline)
  - [set_write_timeout](#set_write_timeout)
  - [str](#str)
  - [wait_for_read](#wait_for_read)
  - [wait_for_write](#wait_for_write)
  - [write](#write)
  - [write_deadline](#write_deadline)
  - [write_ptr](#write_ptr)
  - [write_string](#write_string)
  - [write_timeout](#write_timeout)
- [TcpListener](#TcpListener)
  - [accept](#accept)
  - [accept_only](#accept_only)
  - [accept_deadline](#accept_deadline)
  - [set_accept_deadline](#set_accept_deadline)
  - [accept_timeout](#accept_timeout)
  - [set_accept_timeout](#set_accept_timeout)
  - [wait_for_accept](#wait_for_accept)
  - [close](#close)
  - [addr](#addr)
- [UdpConn](#UdpConn)
  - [write_ptr](#write_ptr)
  - [write](#write)
  - [write_string](#write_string)
  - [write_to_ptr](#write_to_ptr)
  - [write_to](#write_to)
  - [write_to_string](#write_to_string)
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
  - [close](#close)
- [Unix](#Unix)

## Constants
```v
const msg_nosignal = 0x4000
```

[[Return to contents]](#Contents)

```v
const err_connection_refused = error_with_code('net: connection refused', errors_base + 10)
```

[[Return to contents]](#Contents)

```v
const err_option_wrong_type = error_with_code('net: set_option_xxx option wrong type',
	errors_base + 3)
```

[[Return to contents]](#Contents)

```v
const opts_can_set = [
	SocketOption.broadcast,
	.debug,
	.dont_route,
	.keep_alive,
	.linger,
	.oob_inline,
	.receive_buf_size,
	.receive_low_size,
	.receive_timeout,
	.send_buf_size,
	.send_low_size,
	.send_timeout,
	.ipv6_only,
]
```

[[Return to contents]](#Contents)

```v
const error_eagain = int(C.EAGAIN)
```

[[Return to contents]](#Contents)

```v
const err_port_out_of_range = error_with_code('net: port out of range', errors_base + 5)
```

[[Return to contents]](#Contents)

```v
const opts_bool = [SocketOption.broadcast, .debug, .dont_route, .error, .keep_alive, .oob_inline]
```

[[Return to contents]](#Contents)

```v
const err_connect_failed = error_with_code('net: connect failed', errors_base + 7)
```

[[Return to contents]](#Contents)

```v
const errors_base = 0
```

Well defined errors that are returned from socket functions

[[Return to contents]](#Contents)

```v
const opts_int = [
	SocketOption.receive_buf_size,
	.receive_low_size,
	.receive_timeout,
	.send_buf_size,
	.send_low_size,
	.send_timeout,
]
```

[[Return to contents]](#Contents)

```v
const error_eintr = int(C.EINTR)
```

[[Return to contents]](#Contents)

```v
const error_ewouldblock = int(C.EWOULDBLOCK)
```

[[Return to contents]](#Contents)

```v
const err_no_udp_remote = error_with_code('net: no udp remote', errors_base + 6)
```

[[Return to contents]](#Contents)

```v
const error_einprogress = int(C.EINPROGRESS)
```

[[Return to contents]](#Contents)

```v
const err_timed_out_code = errors_base + 9
```

[[Return to contents]](#Contents)

```v
const err_connect_timed_out = error_with_code('net: connect timed out', errors_base + 8)
```

[[Return to contents]](#Contents)

```v
const err_new_socket_failed = error_with_code('net: new_socket failed to create socket',
	errors_base + 1)
```

[[Return to contents]](#Contents)

```v
const msg_dontwait = C.MSG_DONTWAIT
```

[[Return to contents]](#Contents)

```v
const infinite_timeout = time.infinite
```

infinite_timeout should be given to functions when an infinite_timeout is wanted (i.e. functions only ever return with data)

[[Return to contents]](#Contents)

```v
const no_timeout = time.Duration(0)
```

no_timeout should be given to functions when no timeout is wanted (i.e. all functions return instantly)

[[Return to contents]](#Contents)

```v
const err_timed_out = error_with_code('net: op timed out', errors_base + 9)
```

[[Return to contents]](#Contents)

```v
const tcp_default_read_timeout = 30 * time.second
```

[[Return to contents]](#Contents)

```v
const err_option_not_settable = error_with_code('net: set_option_xxx option not settable',
	errors_base + 2)
```

[[Return to contents]](#Contents)

```v
const tcp_default_write_timeout = 30 * time.second
```

[[Return to contents]](#Contents)

## addr_from_socket_handle
```v
fn addr_from_socket_handle(handle int) Addr
```

addr_from_socket_handle returns an address, based on the given integer socket `handle`

[[Return to contents]](#Contents)

## close
```v
fn close(handle int) !
```

close a socket, given its file descriptor `handle`. In non-blocking mode, if `close()` does not succeed immediately, it causes an error to be propagated to `TcpSocket.close()`, which is not intended. Therefore, `select` is used just like `connect()`.

[[Return to contents]](#Contents)

## default_tcp_dialer
```v
fn default_tcp_dialer() Dialer
```

default_tcp_dialer will give you an instance of Dialer, that is suitable for making new tcp connections.

[[Return to contents]](#Contents)

## dial_tcp
```v
fn dial_tcp(oaddress string) !&TcpConn
```

dial_tcp will try to create a new TcpConn to the given address.

[[Return to contents]](#Contents)

## dial_tcp_with_bind
```v
fn dial_tcp_with_bind(saddr string, laddr string) !&TcpConn
```

dial_tcp_with_bind will bind the given local address `laddr` and dial.

[[Return to contents]](#Contents)

## dial_udp
```v
fn dial_udp(raddr string) !&UdpConn
```

[[Return to contents]](#Contents)

## error_code
```v
fn error_code() int
```

[[Return to contents]](#Contents)

## listen_tcp
```v
fn listen_tcp(family AddrFamily, saddr string, options ListenOptions) !&TcpListener
```

[[Return to contents]](#Contents)

## listen_udp
```v
fn listen_udp(laddr string) !&UdpConn
```

[[Return to contents]](#Contents)

## new_ip
```v
fn new_ip(port u16, addr [4]u8) Addr
```

new_ip creates a new Addr from the IPv4 address family, based on the given port and addr

[[Return to contents]](#Contents)

## new_ip6
```v
fn new_ip6(port u16, addr [16]u8) Addr
```

new_ip6 creates a new Addr from the IP6 address family, based on the given port and addr

[[Return to contents]](#Contents)

## new_tcp_socket
```v
fn new_tcp_socket(family AddrFamily) !TcpSocket
```

This is a workaround for issue https://github.com/vlang/v/issues/20858 `noline` ensure that in `-prod` mode(CFLAG = `-O3 -flto`), gcc does not generate wrong instruction sequence

[[Return to contents]](#Contents)

## peer_addr_from_socket_handle
```v
fn peer_addr_from_socket_handle(handle int) !Addr
```

peer_addr_from_socket_handle retrieves the ip address and port number, given a socket handle

[[Return to contents]](#Contents)

## resolve_addrs
```v
fn resolve_addrs(addr string, family AddrFamily, typ SocketType) ![]Addr
```

resolve_addrs converts the given `addr`, `family` and `typ` to a list of addresses

[[Return to contents]](#Contents)

## resolve_addrs_fuzzy
```v
fn resolve_addrs_fuzzy(addr string, typ SocketType) ![]Addr
```

resolve_addrs converts the given `addr` and `typ` to a list of addresses

[[Return to contents]](#Contents)

## resolve_ipaddrs
```v
fn resolve_ipaddrs(addr string, family AddrFamily, typ SocketType) ![]Addr
```

resolve_ipaddrs converts the given `addr`, `family` and `typ` to a list of addresses

[[Return to contents]](#Contents)

## set_blocking
```v
fn set_blocking(handle int, state bool) !
```

set_blocking will change the state of the socket to either blocking, when state is true, or non blocking (false).

[[Return to contents]](#Contents)

## shutdown
```v
fn shutdown(handle int, config ShutdownConfig) int
```

shutdown shutsdown a socket, given its file descriptor `handle`. By default it shuts it down in both directions, both for reading and for writing. You can change that using `net.shutdown(handle, how: .read)` or `net.shutdown(handle, how: .write)` In non-blocking mode, `shutdown()` may not succeed immediately, so `select` is also used to make sure that the function doesn't return an incorrect result.

[[Return to contents]](#Contents)

## socket_error
```v
fn socket_error(potential_code int) !int
```

[[Return to contents]](#Contents)

## socket_error_message
```v
fn socket_error_message(potential_code int, s string) !int
```

[[Return to contents]](#Contents)

## split_address
```v
fn split_address(addr string) !(string, u16)
```

split_address splits an address into its host name and its port

[[Return to contents]](#Contents)

## tcp_socket_from_handle_raw
```v
fn tcp_socket_from_handle_raw(sockfd int) TcpSocket
```

tcp_socket_from_handle_raw is similar to tcp_socket_from_handle, but it does not modify any socket options

[[Return to contents]](#Contents)

## validate_port
```v
fn validate_port(port int) !u16
```

validate_port checks whether a port is valid and returns the port or an error. The valid ports numbers are between 0 and 0xFFFF. For TCP, port number 0 is reserved and cannot be used, while for UDP, the source port is optional and a value of zero means no port. See also https://en.wikipedia.org/wiki/Port_%28computer_networking%29 .

[[Return to contents]](#Contents)

## wrap_error
```v
fn wrap_error(error_code int) !
```

[[Return to contents]](#Contents)

## Connection
```v
interface Connection {
	addr() !Addr
	peer_addr() !Addr
mut:
	read(mut []u8) !int
	write([]u8) !int
	close() !
}
```

Connection provides a generic SOCK_STREAM style interface that protocols can use as a base connection object to support TCP, UNIX Domain Sockets and various proxying solutions.

[[Return to contents]](#Contents)

## Dialer
```v
interface Dialer {
	dial(address string) !Connection
}
```

Dialer is an abstract dialer interface for producing connections to addresses.

[[Return to contents]](#Contents)

## TcpSocket
## set_option_bool
```v
fn (mut s TcpSocket) set_option_bool(opt SocketOption, value bool) !
```

[[Return to contents]](#Contents)

## set_option_int
```v
fn (mut s TcpSocket) set_option_int(opt SocketOption, value int) !
```

[[Return to contents]](#Contents)

## set_dualstack
```v
fn (mut s TcpSocket) set_dualstack(on bool) !
```

[[Return to contents]](#Contents)

## bind
```v
fn (mut s TcpSocket) bind(addr string) !
```

bind a local rddress for TcpSocket

[[Return to contents]](#Contents)

## UdpSocket
## set_option_bool
```v
fn (mut s UdpSocket) set_option_bool(opt SocketOption, value bool) !
```

[[Return to contents]](#Contents)

## set_dualstack
```v
fn (mut s UdpSocket) set_dualstack(on bool) !
```

[[Return to contents]](#Contents)

## close
```v
fn (mut s UdpSocket) close() !
```

close shuts down and closes the socket for communication.

[[Return to contents]](#Contents)

## select
```v
fn (mut s UdpSocket) select(test Select, timeout time.Duration) !bool
```

select waits for no more than `timeout` for the IO operation, defined by `test`, to be available.

[[Return to contents]](#Contents)

## remote
```v
fn (s &UdpSocket) remote() ?Addr
```

remote returns the remote `Addr` address of the socket or `none` if no remote is has been resolved.

[[Return to contents]](#Contents)

## AddrFamily
```v
enum AddrFamily {
	unix   = C.AF_UNIX
	ip     = C.AF_INET
	ip6    = C.AF_INET6
	unspec = C.AF_UNSPEC
}
```

AddrFamily are the available address families

[[Return to contents]](#Contents)

## ShutdownDirection
```v
enum ShutdownDirection {
	read
	write
	read_and_write
}
```

ShutdownDirection is used by `net.shutdown`, for specifying the direction for which the communication will be cut.

[[Return to contents]](#Contents)

## SocketOption
```v
enum SocketOption {
	// TODO: SO_ACCEPT_CONN is not here because windows doesn't support it
	// and there is no easy way to define it
	broadcast        = C.SO_BROADCAST
	debug            = C.SO_DEBUG
	dont_route       = C.SO_DONTROUTE
	error            = C.SO_ERROR
	keep_alive       = C.SO_KEEPALIVE
	linger           = C.SO_LINGER
	oob_inline       = C.SO_OOBINLINE
	reuse_addr       = C.SO_REUSEADDR
	receive_buf_size = C.SO_RCVBUF
	receive_low_size = C.SO_RCVLOWAT
	receive_timeout  = C.SO_RCVTIMEO
	send_buf_size    = C.SO_SNDBUF
	send_low_size    = C.SO_SNDLOWAT
	send_timeout     = C.SO_SNDTIMEO
	socket_type      = C.SO_TYPE
	ipv6_only        = C.IPV6_V6ONLY
	ip_proto_ipv6    = C.IPPROTO_IPV6
	// reuse_port       = C.SO_REUSEPORT // TODO make it work in windows
	// tcp_fastopen     = C.TCP_FASTOPEN // TODO make it work in windows
	// tcp_quickack     = C.TCP_QUICKACK // TODO make it work in os != linux
	// tcp_defer_accept = C.TCP_DEFER_ACCEPT // TODO make it work in windows
}
```

[[Return to contents]](#Contents)

## SocketType
```v
enum SocketType {
	udp       = C.SOCK_DGRAM
	tcp       = C.SOCK_STREAM
	seqpacket = C.SOCK_SEQPACKET
}
```

SocketType are the available sockets

[[Return to contents]](#Contents)

## Addr
```v
struct Addr {
pub:
	len  u8
	f    u8
	addr AddrData
}
```

[[Return to contents]](#Contents)

## family
```v
fn (a Addr) family() AddrFamily
```

family returns the family/kind of the given address `a`

[[Return to contents]](#Contents)

## len
```v
fn (a Addr) len() u32
```

len returns the length in bytes of the address `a`, depending on its family

[[Return to contents]](#Contents)

## port
```v
fn (a Addr) port() !u16
```

port returns the ip or ip6 port of the given address `a`

[[Return to contents]](#Contents)

## str
```v
fn (a Addr) str() string
```

str returns a string representation of the address `a`

[[Return to contents]](#Contents)

## C.addrinfo
```v
struct C.addrinfo {
mut:
	ai_family    int
	ai_socktype  int
	ai_flags     int
	ai_protocol  int
	ai_addrlen   int
	ai_addr      voidptr
	ai_canonname voidptr
	ai_next      voidptr
}
```

[[Return to contents]](#Contents)

## C.fd_set
```v
struct C.fd_set {}
```

[[Return to contents]](#Contents)

## C.sockaddr_in
```v
struct C.sockaddr_in {
mut:
	sin_len    u8
	sin_family u8
	sin_port   u16
	sin_addr   u32
	sin_zero   [8]char
}
```

[[Return to contents]](#Contents)

## C.sockaddr_in6
```v
struct C.sockaddr_in6 {
mut:
	// 1 + 1 + 2 + 4 + 16 + 4 = 28;
	sin6_len      u8     // 1
	sin6_family   u8     // 1
	sin6_port     u16    // 2
	sin6_flowinfo u32    // 4
	sin6_addr     [16]u8 // 16
	sin6_scope_id u32    // 4
}
```

[[Return to contents]](#Contents)

## C.sockaddr_un
```v
struct C.sockaddr_un {
mut:
	sun_len    u8
	sun_family u8
	sun_path   [max_unix_path]char
}
```

[[Return to contents]](#Contents)

## Ip
```v
struct Ip {
	port u16
	addr [4]u8
	// Pad to size so that socket functions
	// dont complain to us (see  in.h and bind())
	// TODO(emily): I would really like to use
	// some constant calculations here
	// so that this doesnt have to be hardcoded
	sin_pad [8]u8
}
```

[[Return to contents]](#Contents)

## str
```v
fn (a Ip) str() string
```

str returns a string representation of `a`

[[Return to contents]](#Contents)

## Ip6
```v
struct Ip6 {
	port      u16
	flow_info u32
	addr      [16]u8
	scope_id  u32
}
```

[[Return to contents]](#Contents)

## str
```v
fn (a Ip6) str() string
```

str returns a string representation of `a`

[[Return to contents]](#Contents)

## ListenOptions
```v
struct ListenOptions {
pub:
	dualstack bool = true
	backlog   int  = 128
}
```

[[Return to contents]](#Contents)

## ShutdownConfig
```v
struct ShutdownConfig {
pub:
	how ShutdownDirection = .read_and_write
}
```

[[Return to contents]](#Contents)

## Socket
```v
struct Socket {
pub:
	handle int
}
```

[[Return to contents]](#Contents)

## address
```v
fn (s &Socket) address() !Addr
```

address gets the address of a socket

[[Return to contents]](#Contents)

## TCPDialer
```v
struct TCPDialer {}
```

TCPDialer is a concrete instance of the Dialer interface, for creating tcp connections.

[[Return to contents]](#Contents)

## dial
```v
fn (t TCPDialer) dial(address string) !Connection
```

dial will try to create a new abstract connection to the given address. It will return an error, if that is not possible.

[[Return to contents]](#Contents)

## TcpConn
```v
struct TcpConn {
pub mut:
	sock           TcpSocket
	handle         int
	write_deadline time.Time
	read_deadline  time.Time
	read_timeout   time.Duration
	write_timeout  time.Duration
	is_blocking    bool = true
}
```

[[Return to contents]](#Contents)

## addr
```v
fn (c &TcpConn) addr() !Addr
```

[[Return to contents]](#Contents)

## close
```v
fn (mut c TcpConn) close() !
```

close closes the tcp connection

[[Return to contents]](#Contents)

## get_blocking
```v
fn (mut con TcpConn) get_blocking() bool
```

get_blocking returns whether the connection is in a blocking state, that is calls to .read_line, C.recv etc will block till there is new data arrived, instead of returning immediately.

[[Return to contents]](#Contents)

## peer_addr
```v
fn (c &TcpConn) peer_addr() !Addr
```

peer_addr retrieves the ip address and port number used by the peer

[[Return to contents]](#Contents)

## peer_ip
```v
fn (c &TcpConn) peer_ip() !string
```

peer_ip retrieves the ip address used by the peer, and returns it as a string

[[Return to contents]](#Contents)

## read
```v
fn (c TcpConn) read(mut buf []u8) !int
```

read reads data from the tcp connection into the mutable buffer `buf`. The number of bytes read is limited to the length of the buffer `buf.len`. The returned value is the number of read bytes (between 0 and `buf.len`).

[[Return to contents]](#Contents)

## read_deadline
```v
fn (mut c TcpConn) read_deadline() !time.Time
```

[[Return to contents]](#Contents)

## read_line
```v
fn (mut con TcpConn) read_line() string
```

read_line is a *simple*, *non customizable*, blocking line reader. It will return a line, ending with LF, or just '', on EOF.

Note: if you want more control over the buffer, please use a buffered IO reader instead: `io.new_buffered_reader({reader: io.make_reader(con)})`

[[Return to contents]](#Contents)

## read_line_max
```v
fn (mut con TcpConn) read_line_max(max_line_len int) string
```

read_line_max is a *simple*, *non customizable*, blocking line reader. It will return a line, ending with LF, '' on EOF. It stops reading, when the result line length exceeds max_line_len.

[[Return to contents]](#Contents)

## read_ptr
```v
fn (c TcpConn) read_ptr(buf_ptr &u8, len int) !int
```

read_ptr reads data from the tcp connection to the given buffer. It reads at most `len` bytes. It returns the number of actually read bytes, which can vary between 0 to `len`.

[[Return to contents]](#Contents)

## read_timeout
```v
fn (c &TcpConn) read_timeout() time.Duration
```

[[Return to contents]](#Contents)

## set_blocking
```v
fn (mut con TcpConn) set_blocking(state bool) !
```

set_blocking will change the state of the connection to either blocking, when state is true, or non blocking (false). The default for `net` tcp connections is the blocking mode. Calling .read_line will set the connection to blocking mode. In general, changing the blocking mode after a successful connection may cause unexpected surprises, so this function is not recommended to be called anywhere but for this file.

[[Return to contents]](#Contents)

## set_read_deadline
```v
fn (mut c TcpConn) set_read_deadline(deadline time.Time)
```

[[Return to contents]](#Contents)

## set_read_timeout
```v
fn (mut c TcpConn) set_read_timeout(t time.Duration)
```

[[Return to contents]](#Contents)

## set_sock
```v
fn (mut c TcpConn) set_sock() !
```

set_sock initialises the c.sock field. It should be called after `.accept_only()!`.

Note: just use `.accept()!`. In most cases it is simpler, and calls `.set_sock()!` for you.

[[Return to contents]](#Contents)

## set_write_deadline
```v
fn (mut c TcpConn) set_write_deadline(deadline time.Time)
```

[[Return to contents]](#Contents)

## set_write_timeout
```v
fn (mut c TcpConn) set_write_timeout(t time.Duration)
```

[[Return to contents]](#Contents)

## str
```v
fn (c TcpConn) str() string
```

[[Return to contents]](#Contents)

## wait_for_read
```v
fn (c TcpConn) wait_for_read() !
```

[[Return to contents]](#Contents)

## wait_for_write
```v
fn (mut c TcpConn) wait_for_write() !
```

[[Return to contents]](#Contents)

## write
```v
fn (mut c TcpConn) write(bytes []u8) !int
```

write blocks and attempts to write all data

[[Return to contents]](#Contents)

## write_deadline
```v
fn (mut c TcpConn) write_deadline() !time.Time
```

[[Return to contents]](#Contents)

## write_ptr
```v
fn (mut c TcpConn) write_ptr(b &u8, len int) !int
```

write_ptr blocks and attempts to write all data

[[Return to contents]](#Contents)

## write_string
```v
fn (mut c TcpConn) write_string(s string) !int
```

write_string blocks and attempts to write all data

[[Return to contents]](#Contents)

## write_timeout
```v
fn (c &TcpConn) write_timeout() time.Duration
```

[[Return to contents]](#Contents)

## TcpListener
```v
struct TcpListener {
pub mut:
	sock            TcpSocket
	accept_timeout  time.Duration
	accept_deadline time.Time
	is_blocking     bool = true
}
```

[[Return to contents]](#Contents)

## accept
```v
fn (mut l TcpListener) accept() !&TcpConn
```

accept a tcp connection from an external source to the listener `l`.

[[Return to contents]](#Contents)

## accept_only
```v
fn (mut l TcpListener) accept_only() !&TcpConn
```

accept_only accepts a tcp connection from an external source to the listener `l`. Unlike `accept`, `accept_only` *will not call* `.set_sock()!` on the result, and is thus faster.



Note: you *need* to call `.set_sock()!` manually, before using theconnection after calling `.accept_only()!`, but that does not have to happen in the same thread that called `.accept_only()!`. The intention of this API, is to have a more efficient way to accept connections, that are later processed by a thread pool, while the main thread remains active, so that it can accept other connections. See also vlib/vweb/vweb.v .

If you do not need that, just call `.accept()!` instead, which will call `.set_sock()!` for you.

[[Return to contents]](#Contents)

## accept_deadline
```v
fn (c &TcpListener) accept_deadline() !time.Time
```

[[Return to contents]](#Contents)

## set_accept_deadline
```v
fn (mut c TcpListener) set_accept_deadline(deadline time.Time)
```

[[Return to contents]](#Contents)

## accept_timeout
```v
fn (c &TcpListener) accept_timeout() time.Duration
```

[[Return to contents]](#Contents)

## set_accept_timeout
```v
fn (mut c TcpListener) set_accept_timeout(t time.Duration)
```

[[Return to contents]](#Contents)

## wait_for_accept
```v
fn (mut c TcpListener) wait_for_accept() !
```

[[Return to contents]](#Contents)

## close
```v
fn (mut c TcpListener) close() !
```

[[Return to contents]](#Contents)

## addr
```v
fn (c &TcpListener) addr() !Addr
```

[[Return to contents]](#Contents)

## UdpConn
```v
struct UdpConn {
pub mut:
	sock UdpSocket
mut:
	write_deadline time.Time
	read_deadline  time.Time
	read_timeout   time.Duration
	write_timeout  time.Duration
}
```

[[Return to contents]](#Contents)

## write_ptr
```v
fn (mut c UdpConn) write_ptr(b &u8, len int) !int
```

sock := UdpSocket{ handle: sbase.handle l: local r: resolve_wrapper(raddr) } }

[[Return to contents]](#Contents)

## write
```v
fn (mut c UdpConn) write(buf []u8) !int
```

[[Return to contents]](#Contents)

## write_string
```v
fn (mut c UdpConn) write_string(s string) !int
```

[[Return to contents]](#Contents)

## write_to_ptr
```v
fn (mut c UdpConn) write_to_ptr(addr Addr, b &u8, len int) !int
```

[[Return to contents]](#Contents)

## write_to
```v
fn (mut c UdpConn) write_to(addr Addr, buf []u8) !int
```

write_to blocks and writes the buf to the remote addr specified

[[Return to contents]](#Contents)

## write_to_string
```v
fn (mut c UdpConn) write_to_string(addr Addr, s string) !int
```

write_to_string blocks and writes the buf to the remote addr specified

[[Return to contents]](#Contents)

## read_ptr
```v
fn (c &UdpConn) read_ptr(buf_ptr &u8, len int) !(int, Addr)
```

read_ptr reads from the socket into `buf_ptr` up to `len` bytes, returning the number of bytes read and the `Addr` read from.

[[Return to contents]](#Contents)

## read
```v
fn (mut c UdpConn) read(mut buf []u8) !(int, Addr)
```

read reads from the socket into buf up to buf.len returning the number of bytes read

[[Return to contents]](#Contents)

## read_deadline
```v
fn (c &UdpConn) read_deadline() !time.Time
```

[[Return to contents]](#Contents)

## set_read_deadline
```v
fn (mut c UdpConn) set_read_deadline(deadline time.Time)
```

[[Return to contents]](#Contents)

## write_deadline
```v
fn (c &UdpConn) write_deadline() !time.Time
```

[[Return to contents]](#Contents)

## set_write_deadline
```v
fn (mut c UdpConn) set_write_deadline(deadline time.Time)
```

[[Return to contents]](#Contents)

## read_timeout
```v
fn (c &UdpConn) read_timeout() time.Duration
```

[[Return to contents]](#Contents)

## set_read_timeout
```v
fn (mut c UdpConn) set_read_timeout(t time.Duration)
```

[[Return to contents]](#Contents)

## write_timeout
```v
fn (c &UdpConn) write_timeout() time.Duration
```

[[Return to contents]](#Contents)

## set_write_timeout
```v
fn (mut c UdpConn) set_write_timeout(t time.Duration)
```

[[Return to contents]](#Contents)

## wait_for_read
```v
fn (c &UdpConn) wait_for_read() !
```

[[Return to contents]](#Contents)

## wait_for_write
```v
fn (mut c UdpConn) wait_for_write() !
```

[[Return to contents]](#Contents)

## str
```v
fn (c &UdpConn) str() string
```

[[Return to contents]](#Contents)

## close
```v
fn (mut c UdpConn) close() !
```

[[Return to contents]](#Contents)

## Unix
```v
struct Unix {
	path [max_unix_path]char
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
