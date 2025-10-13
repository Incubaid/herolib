module ourdb

import incubaid.herolib.ui.console
import incubaid.herolib.core.httpconnection
import json

pub struct OurDBClient {
pub mut:
	conn httpconnection.HTTPConnection
	port int // Server port, default is 3000
	host string
}

@[params]
pub struct OurDBClientArgs {
pub mut:
	port int    = 3000        // Server port, default is 3000
	host string = 'localhost' // Server host
}

struct Response[T] {
	message string // Success message
	data    T      // Response data
}

// KeyValueData represents the data structure returned by the OurDB server
pub struct KeyValueData {
pub:
	id    u32
	value string
}

pub fn new_client(args OurDBClientArgs) !OurDBClient {
	mut client := OurDBClient{
		port: args.port
		host: args.host
	}
	client.conn = client.connection()!
	console.print_green('Client started')
	return client
}

fn (mut client OurDBClient) connection() !&httpconnection.HTTPConnection {
	mut http := httpconnection.new(
		name:  'ourdb_client'
		url:   'http://${client.host}:${client.port}'
		cache: true
		retry: 3
	)!

	client.conn = http
	return http
}

// Sets a value in the database
pub fn (mut client OurDBClient) set(data string) !KeyValueData {
	mut request_body := json.encode({
		'value': data
	})

	req := httpconnection.Request{
		prefix: 'set'
		method: .post
		data:   request_body
	}

	mut http := client.connection()!
	response := http.post_json_str(req)!

	mut decoded_response := json.decode(Response[KeyValueData], response)!
	return decoded_response.data
}

// Gets a value in the database based on it's ID
pub fn (mut client OurDBClient) get(id u32) !KeyValueData {
	req := httpconnection.Request{
		prefix: 'get/${id}'
		method: .get
	}

	mut http := client.connection()!
	response := http.get_json(req)!

	mut decoded_response := json.decode(Response[KeyValueData], response)!
	return decoded_response.data
}

// Deletes a value in the database based on it's ID
pub fn (mut client OurDBClient) delete(id u32) ! {
	req := httpconnection.Request{
		prefix: 'delete/${id}'
		method: .delete
	}

	mut http := client.connection()!
	http.delete(req) or { return error('Failed to delete key due to: ${err}') }
}
