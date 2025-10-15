#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

// Mycelium RPC Client Example
// This example demonstrates how to use the new Mycelium JSON-RPC client
// to interact with a Mycelium node's admin API
import incubaid.herolib.clients.mycelium_rpc
import incubaid.herolib.installers.net.mycelium_installer
import time
import os
import encoding.base64

const mycelium_port = 8990

fn terminate_mycelium() ! {
	// Try to find and kill any running mycelium process
	res := os.execute('pkill mycelium')
	if res.exit_code == 0 {
		println('Terminated existing mycelium processes')
		time.sleep(1 * time.second)
	}
}

fn start_mycelium_node() ! {
	// Start a mycelium node with JSON-RPC API enabled
	println('Starting Mycelium node with JSON-RPC API on port ${mycelium_port}...')

	// Create directory for mycelium data
	os.execute('mkdir -p /tmp/mycelium_rpc_example')

	// Start mycelium in background with both HTTP and JSON-RPC APIs enabled
	spawn fn () {
		cmd := 'cd /tmp/mycelium_rpc_example && mycelium --peers tcp://185.69.166.8:9651 quic://[2a02:1802:5e:0:ec4:7aff:fe51:e36b]:9651 tcp://65.109.18.113:9651 --tun-name tun_rpc_example --tcp-listen-port 9660 --quic-listen-port 9661 --api-addr 127.0.0.1:8989 --jsonrpc-addr 127.0.0.1:${mycelium_port}'
		println('Executing: ${cmd}')
		result := os.execute(cmd)
		if result.exit_code != 0 {
			println('Mycelium failed to start: ${result.output}')
		}
	}()

	// Wait for the node to start (JSON-RPC server needs a bit more time)
	println('Waiting for mycelium to start...')
	time.sleep(5 * time.second)

	// Check if mycelium is running
	check_result := os.execute('pgrep mycelium')
	if check_result.exit_code == 0 {
		println('Mycelium process is running (PID: ${check_result.output.trim_space()})')
	} else {
		println('Warning: Mycelium process not found')
	}

	// Check what ports are listening
	port_check := os.execute('lsof -i :${mycelium_port}')
	if port_check.exit_code == 0 {
		println('Port ${mycelium_port} is listening:')
		println(port_check.output)
	} else {
		println('Warning: Port ${mycelium_port} is not listening')
	}
}

fn main() {
	// Install mycelium if not already installed
	println('Checking Mycelium installation...')
	mut installer := mycelium_installer.get()!
	installer.install()!

	// Clean up any existing processes
	terminate_mycelium() or {}

	defer {
		// Clean up on exit
		terminate_mycelium() or {}
		os.execute('rm -rf /tmp/mycelium_rpc_example')
	}

	// Start mycelium node
	start_mycelium_node()!

	// Create RPC client
	println('\n=== Creating Mycelium RPC Client ===')
	mut client := mycelium_rpc.new_client(
		name: 'example_client'
		url:  'http://localhost:${mycelium_port}'
	)!

	println('Connected to Mycelium node at http://localhost:${mycelium_port}')

	// Example 1: Get node information
	println('\n=== Getting Node Information ===')
	info := client.get_info() or {
		println('Error getting node info: ${err}')
		println('Make sure Mycelium node is running with API enabled')
		return
	}
	println('Node Subnet: ${info.node_subnet}')
	println('Node Public Key: ${info.node_pubkey}')

	// Example 2: List peers
	println('\n=== Listing Peers ===')
	peers := client.get_peers() or {
		println('Error getting peers: ${err}')
		return
	}
	println('Found ${peers.len} peers:')
	for i, peer in peers {
		println('Peer ${i + 1}:')
		println('  Endpoint: ${peer.endpoint.proto}://${peer.endpoint.socket_addr}')
		println('  Type: ${peer.peer_type}')
		println('  Connection State: ${peer.connection_state}')
		println('  TX Bytes: ${peer.tx_bytes}')
		println('  RX Bytes: ${peer.rx_bytes}')
	}

	// Example 3: Get routing information
	println('\n=== Getting Routing Information ===')

	// Get selected routes
	routes := client.get_selected_routes() or {
		println('Error getting selected routes: ${err}')
		return
	}
	println('Selected Routes (${routes.len}):')
	for route in routes {
		println('  ${route.subnet} -> ${route.next_hop} (metric: ${route.metric}, seqno: ${route.seqno})')
	}

	// Get fallback routes
	fallback_routes := client.get_fallback_routes() or {
		println('Error getting fallback routes: ${err}')
		return
	}
	println('Fallback Routes (${fallback_routes.len}):')
	for route in fallback_routes {
		println('  ${route.subnet} -> ${route.next_hop} (metric: ${route.metric}, seqno: ${route.seqno})')
	}

	// Example 4: Topic management
	println('\n=== Topic Management ===')

	// Get default topic action
	default_action := client.get_default_topic_action() or {
		println('Error getting default topic action: ${err}')
		return
	}
	println('Default topic action (accept): ${default_action}')

	// Get configured topics
	topics := client.get_topics() or {
		println('Error getting topics: ${err}')
		return
	}
	println('Configured topics (${topics.len}):')
	for topic in topics {
		println('  - ${topic}')
	}

	// Example 5: Add a test topic (try different names)
	println('\n=== Adding Test Topics ===')
	test_topics := ['example_topic', 'test_with_underscore', 'hello world', 'test', 'a']

	for topic in test_topics {
		println('Trying to add topic: "${topic}"')
		add_result := client.add_topic(topic) or {
			println('Error adding topic "${topic}": ${err}')
			continue
		}
		if add_result {
			println('Successfully added topic: ${topic}')

			// Try to remove it immediately
			remove_result := client.remove_topic(topic) or {
				println('Error removing topic "${topic}": ${err}')
				continue
			}
			if remove_result {
				println('Successfully removed topic: ${topic}')
			}
			break // Stop after first success
		}
	}

	// Example 6: Message operations (demonstration only - requires another node)
	println('\n=== Message Operations (Demo) ===')
	println('Note: These operations require another Mycelium node to be meaningful')

	// Try to pop a message with a short timeout (will likely return "No message ready" error)
	message := client.pop_message(false, 1, '') or {
		println('No messages available (expected): ${err}')
		mycelium_rpc.InboundMessage{}
	}

	if message.id != '' {
		println('Received message:')
		println('  ID: ${message.id}')
		println('  From: ${message.src_ip}')
		println('  Payload: ${base64.decode_str(message.payload)}')
	}

	// Example 7: Peer management (demonstration)
	println('\n=== Peer Management Demo ===')

	// Try to add a peer (this is just for demonstration)
	test_endpoint := 'tcp://127.0.0.1:9999'
	add_peer_result := client.add_peer(test_endpoint) or {
		println('Error adding peer (expected if endpoint is invalid): ${err}')
		false
	}

	if add_peer_result {
		println('Successfully added peer: ${test_endpoint}')

		// Remove the test peer
		remove_peer_result := client.delete_peer(test_endpoint) or {
			println('Error removing peer: ${err}')
			false
		}

		if remove_peer_result {
			println('Successfully removed test peer')
		}
	}

	// Example 8: Get public key from IP (demonstration)
	println('\n=== Public Key Lookup Demo ===')

	// This will likely fail unless we have a valid mycelium IP
	if info.node_subnet != '' {
		// Extract the first IP from the subnet for testing
		subnet_parts := info.node_subnet.split('::')
		if subnet_parts.len > 0 {
			test_ip := subnet_parts[0] + '::1'
			pubkey_response := client.get_public_key_from_ip(test_ip) or {
				println('Could not get public key for IP ${test_ip}: ${err}')
				mycelium_rpc.PublicKeyResponse{}
			}

			if pubkey_response.node_pub_key != '' {
				println('Public key for ${test_ip}: ${pubkey_response.node_pub_key}')
			}
		}
	}

	println('\n=== Mycelium RPC Client Example Completed ===')
	println('This example demonstrated:')
	println('- Getting node information')
	println('- Listing peers and their connection status')
	println('- Retrieving routing information')
	println('- Managing topics')
	println('- Message operations (basic)')
	println('- Peer management')
	println('- Public key lookups')
	println('')
	println('For full message sending/receiving functionality, you would need')
	println('multiple Mycelium nodes running and connected to each other.')
	println('See the Mycelium documentation for more advanced usage.')
}
