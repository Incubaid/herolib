#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.ourtime
import incubaid.herolib.core.jobs.model

// Create a test agent with some sample data
mut agent := model.Agent{
	pubkey:      'ed25519:1234567890abcdef'
	address:     '192.168.1.100'
	port:        9999
	description: 'Test agent for binary encoding'
	status:      model.AgentStatus{
		guid:            'agent-123'
		timestamp_first: ourtime.now()
		timestamp_last:  ourtime.now()
		status:          model.AgentState.ok
	}
	services:    []
	signature:   'signature-data-here'
}

// Add a service
mut service := model.AgentService{
	actor:       'vm'
	description: 'Virtual machine management'
	status:      model.AgentServiceState.ok
	public:      true
	actions:     []
}

// Add an action to the service
mut action := model.AgentServiceAction{
	action:         'create'
	description:    'Create a new virtual machine'
	status:         model.AgentServiceState.ok
	public:         true
	params:         {
		'name':   'Name of the VM'
		'memory': 'Memory in MB'
		'cpu':    'Number of CPU cores'
	}
	params_example: {
		'name':   'my-test-vm'
		'memory': '2048'
		'cpu':    '2'
	}
}

service.actions << action
agent.services << service

// Test binary encoding
binary_data := agent.dumps() or {
	println('Failed to encode agent: ${err}')
	exit(1)
}

println('Successfully encoded agent to binary, size: ${binary_data.len} bytes')

// Test binary decoding
decoded_agent := model.loads(binary_data) or {
	println('Failed to decode agent: ${err}')
	exit(1)
}

// Verify the decoded data matches the original
assert decoded_agent.pubkey == agent.pubkey
assert decoded_agent.address == agent.address
assert decoded_agent.port == agent.port
assert decoded_agent.description == agent.description
assert decoded_agent.signature == agent.signature

// Verify status
assert decoded_agent.status.guid == agent.status.guid
assert decoded_agent.status.status == agent.status.status

// Verify services
assert decoded_agent.services.len == agent.services.len
if decoded_agent.services.len > 0 {
	service1 := decoded_agent.services[0]
	original_service := agent.services[0]

	assert service1.actor == original_service.actor
	assert service1.description == original_service.description
	assert service1.status == original_service.status
	assert service1.public == original_service.public

	// Verify actions
	assert service1.actions.len == original_service.actions.len
	if service1.actions.len > 0 {
		action1 := service1.actions[0]
		original_action := original_service.actions[0]

		assert action1.action == original_action.action
		assert action1.description == original_action.description
		assert action1.status == original_action.status
		assert action1.public == original_action.public

		// Verify params
		assert action1.params.len == original_action.params.len
		for key, value in original_action.params {
			assert key in action1.params
			assert action1.params[key] == value
		}

		// Verify params_example
		assert action1.params_example.len == original_action.params_example.len
		for key, value in original_action.params_example {
			assert key in action1.params_example
			assert action1.params_example[key] == value
		}
	}
}

println('Agent binary encoding/decoding test passed successfully')
