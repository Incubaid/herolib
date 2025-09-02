# module websocket


## Contents
- [new_client](#new_client)
- [new_server](#new_server)
- [AcceptClientFn](#AcceptClientFn)
- [SocketCloseFn](#SocketCloseFn)
- [SocketCloseFn2](#SocketCloseFn2)
- [SocketErrorFn](#SocketErrorFn)
- [SocketErrorFn2](#SocketErrorFn2)
- [SocketMessageFn](#SocketMessageFn)
- [SocketMessageFn2](#SocketMessageFn2)
- [SocketOpenFn](#SocketOpenFn)
- [SocketOpenFn2](#SocketOpenFn2)
- [Uri](#Uri)
  - [str](#str)
- [OPCode](#OPCode)
- [State](#State)
- [Client](#Client)
  - [close](#close)
  - [connect](#connect)
  - [free](#free)
  - [get_state](#get_state)
  - [listen](#listen)
  - [on_close](#on_close)
  - [on_close_ref](#on_close_ref)
  - [on_error](#on_error)
  - [on_error_ref](#on_error_ref)
  - [on_message](#on_message)
  - [on_message_ref](#on_message_ref)
  - [on_open](#on_open)
  - [on_open_ref](#on_open_ref)
  - [parse_frame_header](#parse_frame_header)
  - [ping](#ping)
  - [pong](#pong)
  - [read_next_message](#read_next_message)
  - [reset_state](#reset_state)
  - [set_state](#set_state)
  - [validate_frame](#validate_frame)
  - [write](#write)
  - [write_ptr](#write_ptr)
  - [write_string](#write_string)
- [ClientOpt](#ClientOpt)
- [ClientState](#ClientState)
- [Message](#Message)
  - [free](#free)
- [Server](#Server)
  - [free](#free)
  - [get_ping_interval](#get_ping_interval)
  - [get_state](#get_state)
  - [handle_handshake](#handle_handshake)
  - [listen](#listen)
  - [on_close](#on_close)
  - [on_close_ref](#on_close_ref)
  - [on_connect](#on_connect)
  - [on_message](#on_message)
  - [on_message_ref](#on_message_ref)
  - [set_ping_interval](#set_ping_interval)
  - [set_state](#set_state)
- [ServerClient](#ServerClient)
- [ServerOpt](#ServerOpt)
- [ServerState](#ServerState)

## new_client
```v
fn new_client(address string, opt ClientOpt) !&Client
```

new_client instance a new websocket client

[[Return to contents]](#Contents)

## new_server
```v
fn new_server(family net.AddrFamily, port int, route string, opt ServerOpt) &Server
```

new_server instance a new websocket server on provided port and route

[[Return to contents]](#Contents)

## AcceptClientFn
```v
type AcceptClientFn = fn (mut c ServerClient) !bool
```

[[Return to contents]](#Contents)

## SocketCloseFn
```v
type SocketCloseFn = fn (mut c Client, code int, reason string) !
```

[[Return to contents]](#Contents)

## SocketCloseFn2
```v
type SocketCloseFn2 = fn (mut c Client, code int, reason string, v voidptr) !
```

[[Return to contents]](#Contents)

## SocketErrorFn
```v
type SocketErrorFn = fn (mut c Client, err string) !
```

[[Return to contents]](#Contents)

## SocketErrorFn2
```v
type SocketErrorFn2 = fn (mut c Client, err string, v voidptr) !
```

[[Return to contents]](#Contents)

## SocketMessageFn
```v
type SocketMessageFn = fn (mut c Client, msg &Message) !
```

[[Return to contents]](#Contents)

## SocketMessageFn2
```v
type SocketMessageFn2 = fn (mut c Client, msg &Message, v voidptr) !
```

[[Return to contents]](#Contents)

## SocketOpenFn
```v
type SocketOpenFn = fn (mut c Client) !
```

[[Return to contents]](#Contents)

## SocketOpenFn2
```v
type SocketOpenFn2 = fn (mut c Client, v voidptr) !
```

[[Return to contents]](#Contents)

## Uri
## str
```v
fn (u Uri) str() string
```

str returns the string representation of the Uri

[[Return to contents]](#Contents)

## OPCode
```v
enum OPCode {
	continuation = 0x00
	text_frame   = 0x01
	binary_frame = 0x02
	close        = 0x08
	ping         = 0x09
	pong         = 0x0A
}
```

OPCode represents the supported websocket frame types

[[Return to contents]](#Contents)

## State
```v
enum State {
	connecting = 0
	open
	closing
	closed
}
```

State represents the state of the websocket connection.

[[Return to contents]](#Contents)

## Client
```v
struct Client {
	is_server bool
mut:
	ssl_conn          &ssl.SSLConn = unsafe { nil } // secure connection used when wss is used
	flags             []Flag                // flags used in handshake
	fragments         []Fragment            // current fragments
	message_callbacks []MessageEventHandler // all callbacks on_message
	error_callbacks   []ErrorEventHandler   // all callbacks on_error
	open_callbacks    []OpenEventHandler    // all callbacks on_open
	close_callbacks   []CloseEventHandler   // all callbacks on_close
pub:
	is_ssl        bool   // true if secure socket is used
	uri           Uri    // uri of current connection
	id            string // unique id of client
	read_timeout  i64
	write_timeout i64
pub mut:
	header            http.Header // headers that will be passed when connecting
	conn              &net.TcpConn = unsafe { nil } // underlying TCP socket connection
	nonce_size        int          = 16             // size of nounce used for masking
	panic_on_callback bool               // set to true of callbacks can panic
	client_state      shared ClientState // current state of connection
	// logger used to log messages
	logger        &log.Logger = default_logger
	resource_name string // name of current resource
	last_pong_ut  i64    // last time in unix time we got a pong message
}
```

Client represents websocket client

[[Return to contents]](#Contents)

## close
```v
fn (mut ws Client) close(code int, message string) !
```

close closes the websocket connection

[[Return to contents]](#Contents)

## connect
```v
fn (mut ws Client) connect() !
```

connect connects to remote websocket server

[[Return to contents]](#Contents)

## free
```v
fn (c &Client) free()
```

free handles manual free memory of Client struct

[[Return to contents]](#Contents)

## get_state
```v
fn (ws &Client) get_state() State
```

get_state return the current state of the websocket connection

[[Return to contents]](#Contents)

## listen
```v
fn (mut ws Client) listen() !
```

listen listens and processes incoming messages

[[Return to contents]](#Contents)

## on_close
```v
fn (mut ws Client) on_close(fun SocketCloseFn)
```

on_close registers a callback on closed socket

[[Return to contents]](#Contents)

## on_close_ref
```v
fn (mut ws Client) on_close_ref(fun SocketCloseFn2, ref voidptr)
```

on_close_ref registers a callback on closed socket and provides a reference object

[[Return to contents]](#Contents)

## on_error
```v
fn (mut ws Client) on_error(fun SocketErrorFn)
```

on_error registers a callback on errors

[[Return to contents]](#Contents)

## on_error_ref
```v
fn (mut ws Client) on_error_ref(fun SocketErrorFn2, ref voidptr)
```

on_error_ref registers a callback on errors and provides a reference object

[[Return to contents]](#Contents)

## on_message
```v
fn (mut ws Client) on_message(fun SocketMessageFn)
```

on_message registers a callback on new messages

[[Return to contents]](#Contents)

## on_message_ref
```v
fn (mut ws Client) on_message_ref(fun SocketMessageFn2, ref voidptr)
```

on_message_ref registers a callback on new messages and provides a reference object

[[Return to contents]](#Contents)

## on_open
```v
fn (mut ws Client) on_open(fun SocketOpenFn)
```

on_open registers a callback on successful opening the websocket

[[Return to contents]](#Contents)

## on_open_ref
```v
fn (mut ws Client) on_open_ref(fun SocketOpenFn2, ref voidptr)
```

on_open_ref registers a callback on successful opening the websocket and provides a reference object

[[Return to contents]](#Contents)

## parse_frame_header
```v
fn (mut ws Client) parse_frame_header() !Frame
```

parse_frame_header parses next message by decoding the incoming frames

[[Return to contents]](#Contents)

## ping
```v
fn (mut ws Client) ping() !
```

ping sends ping message to server

[[Return to contents]](#Contents)

## pong
```v
fn (mut ws Client) pong() !
```

pong sends pong message to server,

[[Return to contents]](#Contents)

## read_next_message
```v
fn (mut ws Client) read_next_message() !Message
```

read_next_message reads 1 to n frames to compose a message

[[Return to contents]](#Contents)

## reset_state
```v
fn (mut ws Client) reset_state() !
```

reset_state resets the websocket and initialize default settings

[[Return to contents]](#Contents)

## set_state
```v
fn (mut ws Client) set_state(state State)
```

set_state sets current state of the websocket connection

[[Return to contents]](#Contents)

## validate_frame
```v
fn (mut ws Client) validate_frame(frame &Frame) !
```

validate_client validates client frame rules from RFC6455

[[Return to contents]](#Contents)

## write
```v
fn (mut ws Client) write(bytes []u8, code OPCode) !int
```

write writes a byte array with a websocket messagetype to socket

[[Return to contents]](#Contents)

## write_ptr
```v
fn (mut ws Client) write_ptr(bytes &u8, payload_len int, code OPCode) !int
```

write_ptr writes len bytes provided a byteptr with a websocket messagetype

[[Return to contents]](#Contents)

## write_string
```v
fn (mut ws Client) write_string(str string) !int
```

write_str, writes a string with a websocket texttype to socket

[[Return to contents]](#Contents)

## ClientOpt
```v
struct ClientOpt {
pub:
	read_timeout  i64         = 30 * time.second
	write_timeout i64         = 30 * time.second
	logger        &log.Logger = default_logger
}
```

[[Return to contents]](#Contents)

## ClientState
```v
struct ClientState {
pub mut:
	state State = .closed // current state of connection
}
```

[[Return to contents]](#Contents)

## Message
```v
struct Message {
pub:
	opcode  OPCode // websocket frame type of this message
	payload []u8   // payload of the message
}
```

Message represents a whole message combined from 1 to n frames

[[Return to contents]](#Contents)

## free
```v
fn (m &Message) free()
```

free handles manual free memory of Message struct

[[Return to contents]](#Contents)

## Server
```v
struct Server {
mut:
	logger                  &log.Logger      = default_logger
	ls                      &net.TcpListener = unsafe { nil } // listener used to get incoming connection to socket
	accept_client_callbacks []AcceptClientFn      // accept client callback functions
	message_callbacks       []MessageEventHandler // new message callback functions
	close_callbacks         []CloseEventHandler   // close message callback functions
pub:
	family net.AddrFamily = .ip
	port   int  // port used as listen to incoming connections
	is_ssl bool // true if secure connection (not supported yet on server)
pub mut:
	server_state shared ServerState
}
```

Server represents a websocket server connection

[[Return to contents]](#Contents)

## free
```v
fn (mut s Server) free()
```

free manages manual free of memory for Server instance

[[Return to contents]](#Contents)

## get_ping_interval
```v
fn (mut s Server) get_ping_interval() int
```

get_ping_interval return the interval that the server will send ping messages to clients

[[Return to contents]](#Contents)

## get_state
```v
fn (s &Server) get_state() State
```

get_state return current state in a thread safe way

[[Return to contents]](#Contents)

## handle_handshake
```v
fn (mut s Server) handle_handshake(mut conn net.TcpConn, key string) !&ServerClient
```

handle_handshake use an existing connection to respond to the handshake for a given key

[[Return to contents]](#Contents)

## listen
```v
fn (mut s Server) listen() !
```

listen start listen and process to incoming connections from websocket clients

[[Return to contents]](#Contents)

## on_close
```v
fn (mut s Server) on_close(fun SocketCloseFn)
```

on_close registers a callback on closed socket

[[Return to contents]](#Contents)

## on_close_ref
```v
fn (mut s Server) on_close_ref(fun SocketCloseFn2, ref voidptr)
```

on_close_ref registers a callback on closed socket and provides a reference object

[[Return to contents]](#Contents)

## on_connect
```v
fn (mut s Server) on_connect(fun AcceptClientFn) !
```

on_connect registers a callback when client connects to the server

[[Return to contents]](#Contents)

## on_message
```v
fn (mut s Server) on_message(fun SocketMessageFn)
```

on_message registers a callback on new messages

[[Return to contents]](#Contents)

## on_message_ref
```v
fn (mut s Server) on_message_ref(fun SocketMessageFn2, ref voidptr)
```

on_message_ref registers a callback on new messages and provides a reference object

[[Return to contents]](#Contents)

## set_ping_interval
```v
fn (mut s Server) set_ping_interval(seconds int)
```

set_ping_interval sets the interval that the server will send ping messages to clients

[[Return to contents]](#Contents)

## set_state
```v
fn (mut s Server) set_state(state State)
```

set_state sets current state in a thread safe way

[[Return to contents]](#Contents)

## ServerClient
```v
struct ServerClient {
pub:
	resource_name string // resource that the client access
	client_key    string // unique key of client
pub mut:
	server &Server = unsafe { nil }
	client &Client = unsafe { nil }
}
```

ServerClient represents a connected client

[[Return to contents]](#Contents)

## ServerOpt
```v
struct ServerOpt {
pub:
	logger &log.Logger = default_logger
}
```

[[Return to contents]](#Contents)

## ServerState
```v
struct ServerState {
mut:
	ping_interval int   = 30      // interval for sending ping to clients (seconds)
	state         State = .closed // current state of connection
pub mut:
	clients map[string]&ServerClient // clients connected to this server
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
