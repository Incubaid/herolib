module stage

import freeflowuniverse.herolib.baobab.osis { OSIS }
import freeflowuniverse.herolib.core.redisclient

@[heap]
pub interface IActor {
	name string
mut:
	act(Action) !Action
}

pub struct Actor {
	ActorConfig
mut:
	osis OSIS
}

@[params]
pub struct ActorConfig {
pub:
	name      string
	version   string
	redis_url string = 'localhost:6379'
}

pub fn (config ActorConfig) redis_queue_name() string {
	mut str := 'actor_${config.name}'
	if config.version != '' {
		str += '_${config.version}'
	}
	return str
}

pub fn new_actor(config ActorConfig) !Actor {
	return Actor{
		ActorConfig: config
		osis:        osis.new()!
	}
}

pub fn (a ActorConfig) get_redis_rpc() !redisclient.RedisRpc {
	mut redis := redisclient.new(a.redis_url)!
	return redis.rpc_get(a.redis_queue_name())
}

pub fn (a ActorConfig) version(v string) ActorConfig {
	return ActorConfig{
		...a
		version: v
	}
}

pub fn (a ActorConfig) example() ActorConfig {
	return ActorConfig{
		...a
		version: 'example'
	}
}

pub fn (mut a IActor) handle(method string, data string) !string {
	action := a.act(
		name:   method
		params: data
	)!
	return action.result
}

// // Actor listens to the Redis queue for method invocations
// pub fn (mut a IActor) run() ! {
// 	mut redis := redisclient.new('localhost:6379') or { panic(err) }
// 	mut rpc := redis.rpc_get(a.name)

// 	println('Actor started and listening for tasks...')
// 	for {
// 		rpc.process(a.handle)!
// 		time.sleep(time.millisecond * 100) // Prevent CPU spinning
// 	}
// }
