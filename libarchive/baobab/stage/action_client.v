module stage

import freeflowuniverse.herolib.core.redisclient

// Processor struct for managing procedure calls
pub struct Client {
pub mut:
	rpc redisclient.RedisRpc // Redis RPC mechanism
}

// Parameters for processing a procedure call
@[params]
pub struct Params {
pub:
	timeout int // Timeout in seconds
}

pub struct ClientConfig {
	ActorConfig
pub:
	redis_url string = 'localhost:6379' // url to redis server running
}

pub fn new_client(config ActorConfig) !Client {
	mut redis := redisclient.new(config.redis_url)!
	mut rpc_q := redis.rpc_get(config.redis_queue_name())

	return Client{
		rpc: rpc_q
	}
}

// Process the procedure call
pub fn (mut p Client) call_to_action(action Action, params Params) !Action {
	// Use RedisRpc's `call` to send the call and wait for the response
	response_data := p.rpc.call(redisclient.RPCArgs{
		cmd:     action.name
		data:    action.params
		timeout: u64(params.timeout * 1000) // Convert seconds to milliseconds
		wait:    true
	})!

	return Action{
		...action
		result: response_data
	}
}
