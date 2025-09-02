# module smtp


## Contents
- [new_client](#new_client)
- [BodyType](#BodyType)
- [Attachment](#Attachment)
- [Client](#Client)
  - [reconnect](#reconnect)
  - [send](#send)
  - [quit](#quit)
- [Mail](#Mail)

## new_client
```v
fn new_client(config Client) !&Client
```

new_client returns a new SMTP client and connects to it

[[Return to contents]](#Contents)

## BodyType
```v
enum BodyType {
	text
	html
}
```

[[Return to contents]](#Contents)

## Attachment
```v
struct Attachment {
pub:
	cid      string
	filename string
	bytes    []u8
}
```

[[Return to contents]](#Contents)

## Client
```v
struct Client {
mut:
	conn     net.TcpConn
	ssl_conn &ssl.SSLConn = unsafe { nil }
	reader   ?&io.BufferedReader
pub:
	server   string
	port     int = 25
	username string
	password string
	from     string
	ssl      bool
	starttls bool
pub mut:
	is_open   bool
	encrypted bool
}
```

[[Return to contents]](#Contents)

## reconnect
```v
fn (mut c Client) reconnect() !
```

reconnect reconnects to the SMTP server if the connection was closed

[[Return to contents]](#Contents)

## send
```v
fn (mut c Client) send(config Mail) !
```

send sends an email

[[Return to contents]](#Contents)

## quit
```v
fn (mut c Client) quit() !
```

quit closes the connection to the server

[[Return to contents]](#Contents)

## Mail
```v
struct Mail {
pub:
	from        string
	to          string
	cc          string
	bcc         string
	date        time.Time = time.now()
	subject     string
	body_type   BodyType
	body        string
	attachments []Attachment
	boundary    string
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
