# module sse


## Contents
- [start_connection](#start_connection)
- [SSEConnection](#SSEConnection)
  - [send_message](#send_message)
  - [close](#close)
- [SSEMessage](#SSEMessage)

## start_connection
```v
fn start_connection(mut ctx veb.Context) &SSEConnection
```

start an SSE connection

[[Return to contents]](#Contents)

## SSEConnection
```v
struct SSEConnection {
pub mut:
	conn &net.TcpConn @[required]
}
```

[[Return to contents]](#Contents)

## send_message
```v
fn (mut sse SSEConnection) send_message(message SSEMessage) !
```

send_message sends a single message to the http client that listens for SSE. It does not close the connection, so you can use it many times in a loop.

[[Return to contents]](#Contents)

## close
```v
fn (mut sse SSEConnection) close()
```

send a 'close' event and close the tcp connection.

[[Return to contents]](#Contents)

## SSEMessage
```v
struct SSEMessage {
pub mut:
	id    string
	event string
	data  string
	retry int
}
```

This module implements the server side of `Server Sent Events`. See https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#event_stream_format as well as https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events for detailed description of the protocol, and a simple web browser client example.

> Event stream format > The event stream is a simple stream of text data which must be encoded using UTF-8. > Messages in the event stream are separated by a pair of newline characters. > A colon as the first character of a line is in essence a comment, and is ignored. > Note: The comment line can be used to prevent connections from timing out; > a server can send a comment periodically to keep the connection alive. > > Each message consists of one or more lines of text listing the fields for that message. > Each field is represented by the field name, followed by a colon, followed by the text > data for that field's value.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:17:41
