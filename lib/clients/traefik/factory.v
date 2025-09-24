module traefik

import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.osal.traefik as osal_traefik

__global (
	traefik_managers map[string]&TraefikManager
)

@[params]
pub struct FactoryArgs {
pub mut:
	name      string = 'default'
	redis_url string = '127.0.0.1:6379'
}

pub fn new(args FactoryArgs) !&TraefikManager {
	name := texttools.name_fix(args.name)
	if name in traefik_managers {
		return traefik_managers[name]
	}

	mut redis := redisclient.core_get(redisclient.get_redis_url(args.redis_url)!)!

	mut manager := &TraefikManager{
		name:   name
		redis:  redis
		config: osal_traefik.new_traefik_config()
	}

	// Set redis connection in config
	manager.config.redis = redis

	traefik_managers[name] = manager
	return manager
}

pub fn get(args FactoryArgs) !&TraefikManager {
	name := texttools.name_fix(args.name)
	return traefik_managers[name] or {
		return error('traefik manager with name "${name}" does not exist')
	}
}

pub fn default() !&TraefikManager {
	if traefik_managers.len == 0 {
		return new(name: 'default')!
	}
	return get(name: 'default')!
}
