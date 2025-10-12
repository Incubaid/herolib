module qdrant

import incubaid.herolib.core.httpconnection
import json

// QDrant usage
pub struct QDrantUsage {
pub mut:
	cpu      int // CPU usage
	io_read  int // I/O read usage
	io_write int // I/O write usage
}

// Top-level response structure
pub struct QDrantResponse[T] {
pub mut:
	usage  QDrantUsage // Usage information
	result T           // The result
	status string      // Response status
	time   f64         // Response time
}

pub struct QDrantErrorResponse {
pub mut:
	status QDrantError // Response status
	time   f64         // Response time
}

// Qdrant error response
pub struct QDrantError {
pub mut:
	error string // Error message
}

// Service information
pub struct ServiceInfo {
pub mut:
	version string  // Version of the Qdrant server
	commit  ?string // Git commit hash
}

// Health check response
pub struct HealthCheckResponse {
pub mut:
	title   string // Title of the health check
	status  string // Status of the health check
	version string // Version of the Qdrant server
}

// Get service information
pub fn (mut self QDrantClient) get_service_info() !QDrantResponse[ServiceInfo] {
	mut http_conn := self.httpclient()!
	req := httpconnection.Request{
		method: .get
		prefix: '/telemetry'
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error getting service info: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[ServiceInfo], response.data)!
}

// Check health of the Qdrant server
pub fn (mut self QDrantClient) health_check() !bool {
	mut http_conn := self.httpclient()!
	req := httpconnection.Request{
		method: .get
		prefix: '/healthz'
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		return false
	}

	return true
}

// httpclient creates a new HTTP connection to the Qdrant API
fn (mut self QDrantClient) httpclient() !&httpconnection.HTTPConnection {
	mut http_conn := httpconnection.new(
		name: 'Qdrant_vclient'
		url:  self.url
	)!

	// Add authentication header if API key is provided
	if self.secret.len > 0 {
		http_conn.default_header.add_custom('api-key', self.secret)!
	}

	return http_conn
}
