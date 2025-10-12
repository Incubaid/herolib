module traefik

import json
import incubaid.herolib.core.redisclient

// new_traefik_config creates a new TraefikConfig
pub fn new_traefik_config() TraefikConfig {
	return TraefikConfig{
		routers:     []RouteConfig{}
		services:    []ServiceConfig{}
		middlewares: []MiddlewareConfig{}
		tls:         []TLSConfig{}
	}
}

// add_route adds a route configuration
pub fn (mut tc TraefikConfig) add_route(args RouteConfig) {
	tc.routers << RouteConfig{
		name:        args.name
		rule:        args.rule
		service:     args.service
		middlewares: args.middlewares
		priority:    args.priority
		tls:         args.tls
	}
}

// add_service adds a service configuration
pub fn (mut tc TraefikConfig) add_service(args ServiceConfig) {
	tc.services << ServiceConfig{
		name:          args.name
		load_balancer: args.load_balancer
	}
}

// add_middleware adds a middleware configuration
pub fn (mut tc TraefikConfig) add_middleware(args MiddlewareConfig) {
	tc.middlewares << MiddlewareConfig{
		name:     args.name
		typ:      args.typ
		settings: args.settings
	}
}

// add_tls adds a TLS configuration
pub fn (mut tc TraefikConfig) add_tls(args TLSConfig) {
	tc.tls << TLSConfig{
		domain:    args.domain
		cert_file: args.cert_file
		key_file:  args.key_file
	}
}

// set populates Redis with the Traefik configuration
pub fn (tc TraefikConfig) set() ! {
	mut redis := tc.redis or { redisclient.core_get()! }

	// Store router configurations
	for router in tc.routers {
		base_key := 'traefik/http/routers/${router.name}'

		// Set router rule
		redis.set('${base_key}/rule', router.rule)!

		// Set service
		redis.set('${base_key}/service', router.service)!

		// Set middlewares if any
		if router.middlewares.len > 0 {
			redis.set('${base_key}/middlewares', json.encode(router.middlewares))!
		}

		// Set priority if non-zero
		if router.priority != 0 {
			redis.set('${base_key}/priority', router.priority.str())!
		}

		// Set TLS if enabled
		if router.tls {
			redis.set('${base_key}/tls', 'true')!
		}
	}

	// Store service configurations
	for service in tc.services {
		base_key := 'traefik/http/services/${service.name}'

		// Set load balancer servers
		mut servers := []map[string]string{}
		for server in service.load_balancer.servers {
			servers << {
				'url': server.url
			}
		}
		redis.set('${base_key}/loadbalancer/servers', json.encode(servers))!
	}

	// Store middleware configurations
	for middleware in tc.middlewares {
		base_key := 'traefik/http/middlewares/${middleware.name}'

		// Set middleware type
		redis.set('${base_key}/${middleware.typ}', json.encode(middleware.settings))!
	}

	// Store TLS configurations
	for tls in tc.tls {
		base_key := 'traefik/tls/certificates'
		cert_config := {
			'certFile': tls.cert_file
			'keyFile':  tls.key_file
		}
		redis.hset(base_key, tls.domain, json.encode(cert_config))!
	}
}

// example shows how to use the Traefik configuration
pub fn (mut tc TraefikConfig) example() ! {
	// Add a basic router with service
	tc.add_route(
		name:        'my-router'
		rule:        'Host(`example.com`)'
		service:     'my-service'
		middlewares: ['auth']
		tls:         true
	)

	// Add the corresponding service
	tc.add_service(
		name:          'my-service'
		load_balancer: LoadBalancerConfig{
			servers: [
				ServerConfig{
					url: 'http://localhost:8080'
				},
				ServerConfig{
					url: 'http://localhost:8081'
				},
			]
		}
	)

	// Add a basic auth middleware
	tc.add_middleware(
		name:     'auth'
		typ:      'basicAuth'
		settings: {
			'users': '["test:${apr1}${H6uskkkW}${IgXLP6ewTrSuBkTrqE8wj}/"]'
		}
	)

	// Add TLS configuration
	tc.add_tls(
		domain:    'example.com'
		cert_file: '/path/to/cert.pem'
		key_file:  '/path/to/key.pem'
	)

	// Store configuration in Redis
	tc.set()!
}
