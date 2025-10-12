module openrpc

import incubaid.herolib.core.redisclient
import incubaid.herolib.core.jobs.model

// Generic OpenRPC server that handles all managers
pub struct OpenRPCServer {
mut:
	redis  &redisclient.Redis
	queue  &redisclient.RedisQueue
	runner &model.HeroRunner
}

// Create new OpenRPC server with Redis connection
pub fn server_start() ! {
	redis := redisclient.core_get()!
	mut runner := model.new()!
	mut s := &OpenRPCServer{
		redis:  redis
		queue:  &redisclient.RedisQueue{
			key:   rpc_queue
			redis: redis
		}
		runner: runner
	}
	s.start()!
}
