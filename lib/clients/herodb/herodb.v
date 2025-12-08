module herodb

import json
import incubaid.herolib.core.httpconnection

// JSON-RPC 2.0 Structures

struct JsonRpcRequest {
	jsonrpc string = '2.0'
	method  string
	params  []string
	id      int
}

struct JsonRpcResponse[T] {
	jsonrpc string
	result  T
	error   ?JsonRpcError
	id      int
}

struct JsonRpcError {
	code    int
	message string
	data    string
}

// HeroDB Specific Structures

pub struct InstanceMetadata {
pub:
	index        int
	name         string
	// backend_type can be a string ("InMemory") or an object ({"Redb": "path"}).
	// We use the `raw` attribute to capture the raw JSON and parse it manually.
	backend_type string @[raw]
	created_at   string
}

// Helper struct to represent the parsed backend info in a usable way
pub struct BackendInfo {
pub:
	type_name string // "InMemory", "Redb", "LanceDb"
	path      string // Empty for InMemory
}

pub struct HeroDB {
pub:
	server_url string
pub mut:
	conn ?&httpconnection.HTTPConnection
}

pub struct Config {
pub:
	url string = 'http://localhost:3000'
}

pub fn new(cfg Config) !HeroDB {
	return HeroDB{
		server_url: cfg.url
	}
}

pub fn (mut self HeroDB) connection() !&httpconnection.HTTPConnection {
	if mut conn := self.conn {
		return conn
	}

	mut new_conn := httpconnection.new(
		name:  'herodb'
		url:   self.server_url
		retry: 3
	)!
	self.conn = new_conn
	return new_conn
}

fn (mut self HeroDB) rpc_call[T](method string) !T {
	mut conn := self.connection()!

	req := JsonRpcRequest{
		method: method
		id:     1
		params: []
	}

	response := conn.post_json_generic[JsonRpcResponse[T]](
		method:     .post
		prefix:     ''
		data:       json.encode(req)
		dataformat: .json
	)!

	if err := response.error {
		return error('RPC Error ${err.code}: ${err.message}')
	}

	return response.result
}

pub fn (mut self HeroDB) list_instances() ![]InstanceMetadata {
	return self.rpc_call[[]InstanceMetadata]('db_listInstances')!
}

pub fn (m InstanceMetadata) get_backend_info() !BackendInfo {
	if m.backend_type.len == 0 {
		return error('empty backend_type')
	}
	if m.backend_type[0] == `"` {
		// It's a string
		val := json.decode(string, m.backend_type)!
		return BackendInfo{
			type_name: val
		}
	} else if m.backend_type[0] == `{` {
		// It's an object
		val := json.decode(map[string]string, m.backend_type)!
		for k, v in val {
			return BackendInfo{
				type_name: k
				path:      v
			}
		}
	}
	return error('unknown backend_type format: ${m.backend_type}')
}