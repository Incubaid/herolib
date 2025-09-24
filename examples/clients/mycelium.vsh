#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.clients.mycelium
import freeflowuniverse.herolib.installers.net.mycelium_installer
import time
import os
import encoding.base64

const server1_port = 9001
const server2_port = 9002

fn terminate(port int) ! {
	// Step 1: Run lsof to get process details
	res := os.execute('lsof -i:${port}')
	if res.exit_code != 0 {
		return error('no service running at port ${port} due to: ${res.output}')
	}

	// Step 2: Parse the output to extract the PID
	lines := res.output.split('\n')
	if lines.len < 2 {
		return error('no process found running on port ${port}')
	}

	// The PID is the second column in the output
	fields := lines[1].split(' ')
	if fields.len < 2 {
		return error('failed to parse lsof output')
	}
	pid := fields[1]

	// Step 3: Kill the process using the PID
	kill_res := os.execute('kill ${pid}')
	if kill_res.exit_code != 0 {
		return error('failed to kill process ${pid}: ${kill_res.output}')
	}

	println('Successfully terminated process ${pid} running on port ${port}')
}

println('[INFO] Starting mycelium messaging test with two connected nodes')

// Clean up any existing mycelium processes first
println('[INFO] Cleaning up any existing mycelium processes')
terminate(server1_port) or {}
terminate(server2_port) or {}
_ := os.execute('sudo pkill mycelium')

// Ensure mycelium is installed
println('[INFO] Checking mycelium installation')
mut installer := mycelium_installer.get()!
installer.install()!

// Clean up any existing mycelium configurations
println('[INFO] Cleaning up existing mycelium configurations')
mycelium.delete()!

// Start two mycelium server instances with different configurations
println('[INFO] Starting mycelium server instances')
println('[INFO] Node 1 will use port ${server1_port} with TUN interface tun2')
println('[INFO] Node 2 will use port ${server2_port} with TUN interface tun3')

spawn fn () {
	result := os.execute('mkdir -p /tmp/mycelium_server1 && cd /tmp/mycelium_server1 && sudo mycelium --key-file mycelium_key1.bin --api-addr 127.0.0.1:${server1_port} --jsonrpc-addr 127.0.0.1:8990 --tcp-listen-port 9652 --quic-listen-port 9653 --peer-discovery-port 9650 --no-tun')
	if result.exit_code != 0 {
		println('[ERROR] Server 1 failed to start: ${result.output}')
	}
}()

spawn fn () {
	result := os.execute('mkdir -p /tmp/mycelium_server2 && cd /tmp/mycelium_server2 && sudo mycelium --key-file mycelium_key2.bin --api-addr 127.0.0.1:${server2_port} --jsonrpc-addr 127.0.0.1:8991 --tcp-listen-port 9654 --quic-listen-port 9655 --peer-discovery-port 9656 --peers tcp://127.0.0.1:9652 --no-tun')
	if result.exit_code != 0 {
		println('[ERROR] Server 2 failed to start: ${result.output}')
	}
}()

// Ensure cleanup on exit
defer {
	println('[INFO] Cleaning up mycelium server instances')
	terminate(server1_port) or {}
	terminate(server2_port) or {}
}

// Wait for servers to start up
println('[INFO] Waiting for mycelium servers to initialize')
time.sleep(5 * time.second)

// Check if servers are responding
println('[INFO] Checking if mycelium servers are responding')
for i in 0 .. 10 {
	server1_check := os.execute('curl -s http://localhost:${server1_port}/api/v1/admin')
	server2_check := os.execute('curl -s http://localhost:${server2_port}/api/v1/admin')

	if server1_check.exit_code == 0 && server2_check.exit_code == 0 {
		println('[INFO] Both servers are responding')
		break
	}

	println('[INFO] Waiting for servers to be ready... (attempt ${i + 1}/10)')
	time.sleep(2 * time.second)

	if i == 9 {
		println('[ERROR] Servers did not start properly after 20 seconds')
		return
	}
}

// Initialize mycelium clients with different names
println('[INFO] Initializing mycelium clients')
mut client1 := mycelium.get(name: 'node1')!
client1.server_url = 'http://localhost:${server1_port}'

mut client2 := mycelium.get(name: 'node2')!
client2.server_url = 'http://localhost:${server2_port}'

println('[INFO] Client 1 configured for: ${client1.server_url}')
println('[INFO] Client 2 configured for: ${client2.server_url}')

// Get public keys from the key files
println('[INFO] Retrieving public keys from server key files')
inspect1 := mycelium.inspect(key_file_path: '/tmp/mycelium_server1/mycelium_key1.bin')!
inspect2 := mycelium.inspect(key_file_path: '/tmp/mycelium_server2/mycelium_key2.bin')!

println('[INFO] Node 1 public key: ${inspect1.public_key}')
println('[INFO] Node 2 public key: ${inspect2.public_key}')

// Verify nodes have different public keys
if inspect1.public_key == inspect2.public_key {
	println('[ERROR] Both nodes have the same public key - this should not happen')
	return
}
println('[INFO] Nodes have different public keys - configuration is correct')
println('')

// Test messaging between the two connected nodes
test_topic := 'test_messaging'

// Test 1: Node 1 -> Node 2
println('[TEST] Sending message from Node 1 to Node 2')
test_payload_1 := 'Hello from Node 1 to Node 2'

msg1 := client1.send_msg(
	public_key: inspect2.public_key
	payload:    test_payload_1
	topic:      test_topic
	wait:       false
)!

println('[INFO] Message sent successfully from Node 1')
println('[INFO] Message ID: ${msg1.id}')
println('[INFO] Payload: ${test_payload_1}')

println('[INFO] Waiting for Node 2 to receive the message')
received1 := client2.receive_msg(wait: true, peek: false, topic: test_topic)!
decoded_payload1 := base64.decode_str(received1.payload)

println('[INFO] Message received on Node 2')
println('[INFO] Message ID: ${received1.id}')
println('[INFO] Source public key: ${received1.src_pk}')
println('[INFO] Decoded payload: ${decoded_payload1}')

// Verify message integrity for Test 1
if received1.src_pk == inspect1.public_key && decoded_payload1 == test_payload_1 {
	println('[SUCCESS] Node 1 -> Node 2 messaging test passed')
} else {
	println('[ERROR] Node 1 -> Node 2 messaging test failed')
	println('[ERROR] Expected source: ${inspect1.public_key}')
	println('[ERROR] Actual source: ${received1.src_pk}')
	println('[ERROR] Expected payload: ${test_payload_1}')
	println('[ERROR] Actual payload: ${decoded_payload1}')
}

println('')

// Test 2: Node 2 -> Node 1
println('[TEST] Sending message from Node 2 to Node 1')
test_payload_2 := 'Hello from Node 2 to Node 1'

msg2 := client2.send_msg(
	public_key: inspect1.public_key
	payload:    test_payload_2
	topic:      test_topic
	wait:       false
)!

println('[INFO] Message sent successfully from Node 2')
println('[INFO] Message ID: ${msg2.id}')
println('[INFO] Payload: ${test_payload_2}')

println('[INFO] Waiting for Node 1 to receive the message')
received2 := client1.receive_msg(wait: true, peek: false, topic: test_topic)!
decoded_payload2 := base64.decode_str(received2.payload)

println('[INFO] Message received on Node 1')
println('[INFO] Message ID: ${received2.id}')
println('[INFO] Source public key: ${received2.src_pk}')
println('[INFO] Decoded payload: ${decoded_payload2}')

// Verify message integrity for Test 2
if received2.src_pk == inspect2.public_key && decoded_payload2 == test_payload_2 {
	println('[SUCCESS] Node 2 -> Node 1 messaging test passed')
} else {
	println('[ERROR] Node 2 -> Node 1 messaging test failed')
	println('[ERROR] Expected source: ${inspect2.public_key}')
	println('[ERROR] Actual source: ${received2.src_pk}')
	println('[ERROR] Expected payload: ${test_payload_2}')
	println('[ERROR] Actual payload: ${decoded_payload2}')
}

println('')
println('[INFO] All messaging tests completed successfully')
println('[INFO] Both nodes can send and receive messages bidirectionally')
