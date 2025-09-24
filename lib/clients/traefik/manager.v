module traefik

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.osal.traefik as osal_traefik
import freeflowuniverse.herolib.core.texttools

@[heap]
pub struct TraefikManager {
pub mut:
	name        string
	redis       &redisclient.Redis
	config      osal_traefik.TraefikConfig
	entrypoints []EntryPointConfig
}

pub struct EntryPointConfig {
pub mut:
	name    string @[required]
	address string @[required]
	tls     bool
}

@[params]
pub struct RouterAddArgs {
pub mut:
	name        string @[required]
	rule        string @[required]
	service     string @[required]
	entrypoints []string
	middlewares []string
	tls         bool
	priority    int
}

@[params]
pub struct ServiceAddArgs {
pub mut:
	name     string   @[required]
	servers  []string @[required]
	strategy string = 'wrr' // wrr or p2c
}

@[params]
pub struct MiddlewareAddArgs {
pub mut:
	name     string @[required]
	typ      string @[required]
	settings map[string]string
}

@[params]
pub struct EntryPointAddArgs {
pub mut:
	name    string @[required]
	address string @[required]
	tls     bool
}

// Add router configuration
pub fn (mut tm TraefikManager) router_add(args RouterAddArgs) ! {
	tm.config.add_route(
		name:        texttools.name_fix(args.name)
		rule:        args.rule
		service:     texttools.name_fix(args.service)
		middlewares: args.middlewares.map(texttools.name_fix(it))
		priority:    args.priority
		tls:         args.tls
	)
}

// Add service configuration
pub fn (mut tm TraefikManager) service_add(args ServiceAddArgs) ! {
	mut servers := []osal_traefik.ServerConfig{}
	for server_url in args.servers {
		servers << osal_traefik.ServerConfig{
			url: server_url.trim_space()
		}
	}

	tm.config.add_service(
		name:          texttools.name_fix(args.name)
		load_balancer: osal_traefik.LoadBalancerConfig{
			servers: servers
		}
	)
}

// Add middleware configuration
pub fn (mut tm TraefikManager) middleware_add(args MiddlewareAddArgs) ! {
	tm.config.add_middleware(
		name:     texttools.name_fix(args.name)
		typ:      args.typ
		settings: args.settings
	)
}

// Add entrypoint configuration (stored separately as these are typically static config)
pub fn (mut tm TraefikManager) entrypoint_add(args EntryPointAddArgs) ! {
	entrypoint := EntryPointConfig{
		name:    texttools.name_fix(args.name)
		address: args.address
		tls:     args.tls
	}

	// Check if entrypoint already exists
	for mut ep in tm.entrypoints {
		if ep.name == entrypoint.name {
			ep.address = entrypoint.address
			ep.tls = entrypoint.tls
			return
		}
	}

	tm.entrypoints << entrypoint
}

// Apply all configurations to Redis
pub fn (mut tm TraefikManager) apply() ! {
	// Apply dynamic configuration (routers, services, middlewares)
	tm.config.set()!

	// Store entrypoints separately (these would typically be in static config)
	for ep in tm.entrypoints {
		tm.redis.hset('traefik:entrypoints', ep.name, '${ep.address}|${ep.tls}')!
	}
}

// Get all entrypoints
pub fn (mut tm TraefikManager) entrypoints_get() ![]EntryPointConfig {
	return tm.entrypoints.clone()
}

// Clear all configurations
pub fn (mut tm TraefikManager) clear() ! {
	tm.config = osal_traefik.new_traefik_config()
	tm.config.redis = tm.redis
	tm.entrypoints = []EntryPointConfig{}

	// Clear Redis keys
	keys := tm.redis.keys('traefik/*')!
	for key in keys {
		tm.redis.del(key)!
	}
}

// Get configuration status
pub fn (mut tm TraefikManager) status() !map[string]int {
	return {
		'routers':     tm.config.routers.len
		'services':    tm.config.services.len
		'middlewares': tm.config.middlewares.len
		'entrypoints': tm.entrypoints.len
	}
}
