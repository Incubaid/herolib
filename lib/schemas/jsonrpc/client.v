module jsonrpc

import freeflowuniverse.herolib.ui.console

// IRPCTransportClient defines the interface for transport mechanisms used by the JSON-RPC client.
// This allows for different transport implementations (HTTP, WebSocket, etc.) to be used
// with the same client code.
pub interface IRPCTransportClient {
mut:
	// send transmits a JSON-RPC request string and returns the response as a string.
	// Parameters:
	//   - request: The JSON-RPC request string to send
	//   - params: Configuration parameters for the send operation
	// Returns:
	//   - The response string or an error if the send operation fails
	send(request string, params SendParams) !string
	url() string
}

// SendParams defines configuration options for sending JSON-RPC requests.
// These parameters control timeout and retry behavior.
@[params]
pub struct SendParams {
pub:
	// Maximum time in seconds to wait for a response (default: 2)
	timeout int = 2

	// Number of times to retry the request if it fails
	retry int
}

// Client implements a JSON-RPC 2.0 client that can send requests and process responses.
// It uses a pluggable transport layer that implements the IRPCTransportClient interface.
pub struct Client {
pub mut:
	// The transport implementation used to send requests and receive responses
	transport IRPCTransportClient
}

// new_client creates a new JSON-RPC client with the specified transport.
//
// Parameters:
//   - client: A Client struct with the transport field initialized
//
// Returns:
//   - A pointer to a new Client instance
pub fn new_client(transport IRPCTransportClient) &Client {
	mut cl := Client{
		transport: transport
	}
	return &cl
}

// send sends a JSON-RPC request with parameters of type T and expects a response with result of type D.
// This method handles the full request-response cycle including validation and error handling.
//
// Type Parameters:
//   - T: The type of the request parameters
//   - D: The expected type of the response result
//
// Parameters:
//   - request: The JSON-RPC request object with parameters of type T
//   - params: Configuration parameters for the send operation
//
// Returns:
//   - The response result of type D or an error if any step in the process fails
pub fn (mut c Client) send[T, D](request RequestGeneric[T], params SendParams) !D {
	// Send the encoded request through the transport layer
	console.print_debug('Sending request: \n*****\n${request.encode()}\n*****\n')
	response_json := c.transport.send(request.encode(), params) or {
		if err.msg().contains('net: op timed out') {
			console.print_debug('time out')
		}
		// print_backtrace()
		// println(err)
		// $dbg;
		return error('Failed to send request for jsonrpc:\n${request.encode()}\n${err}')
	}
	// Decode the response JSON into a strongly-typed response object
	response := decode_response_generic[D](response_json) or {
		return error('Unable to decode response.\nRequest: ${request.encode()}\nResponse: ${response_json}\nError: ${err}')
	}

	// Validate the response according to the JSON-RPC specification
	response.validate() or { return error('Received invalid response: ${err}') }

	// Ensure the response ID matches the request ID to prevent response/request mismatch
	if response.id != request.id {
		return error('Received response with different id ${response}')
	}

	// Return the result or propagate any error from the response
	return response.result() or {
		myerror := response.error_ or {
			return error('Failed to get error from response:\nRequest: ${request.encode()}\nResponse: ${response_json}\n${err}')
		}
		// print_backtrace()
		mut myreq := request.encode()
		if c.transport is UnixSocketTransport {
			myreq = "To Test:\n**********\necho '\n${myreq}\n' | nc -U ${c.transport.url()}\n**********"
		} else {
			myreq = 'Path:${c.transport.url()}\nRequest:\n${myreq}'
		}
		return error('\nRPC Request Failed.\n${myreq}\n${myerror}')
	}
}
