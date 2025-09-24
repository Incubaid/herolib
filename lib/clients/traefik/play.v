module traefik

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.ui.console

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'traefik.') {
		return
	}

	// Get or create default traefik manager
	mut manager := default()!

	// Process entrypoints first
	play_entrypoints(mut plbook, mut manager)!

	// Process services (before routers that might reference them)
	play_services(mut plbook, mut manager)!

	// Process middlewares (before routers that might reference them)
	play_middlewares(mut plbook, mut manager)!

	// Process routers
	play_routers(mut plbook, mut manager)!

	// Apply all configurations to Redis
	manager.apply()!

	console.print_debug('Traefik configuration applied successfully')
}

fn play_entrypoints(mut plbook PlayBook, mut manager TraefikManager) ! {
	entrypoint_actions := plbook.find(filter: 'traefik.entrypoint')!

	for mut action in entrypoint_actions {
		mut p := action.params

		manager.entrypoint_add(
			name:    p.get('name')!
			address: p.get('address')!
			tls:     p.get_default_false('tls')
		)!

		action.done = true
	}
}

fn play_routers(mut plbook PlayBook, mut manager TraefikManager) ! {
	router_actions := plbook.find(filter: 'traefik.router')!

	for mut action in router_actions {
		mut p := action.params

		// Parse entrypoints list
		mut entrypoints := []string{}
		if entrypoints_str := p.get_default('entrypoints', '') {
			if entrypoints_str.len > 0 {
				entrypoints = entrypoints_str.split(',').map(it.trim_space())
			}
		}

		// Parse middlewares list
		mut middlewares := []string{}
		if middlewares_str := p.get_default('middlewares', '') {
			if middlewares_str.len > 0 {
				middlewares = middlewares_str.split(',').map(it.trim_space())
			}
		}

		manager.router_add(
			name:        p.get('name')!
			rule:        p.get('rule')!
			service:     p.get('service')!
			entrypoints: entrypoints
			middlewares: middlewares
			tls:         p.get_default_false('tls')
			priority:    p.get_int_default('priority', 0)
		)!

		action.done = true
	}
}

fn play_services(mut plbook PlayBook, mut manager TraefikManager) ! {
	service_actions := plbook.find(filter: 'traefik.service')!

	for mut action in service_actions {
		mut p := action.params

		// Parse servers list
		servers_str := p.get('servers')!
		servers := servers_str.split(',').map(it.trim_space())

		manager.service_add(
			name:     p.get('name')!
			servers:  servers
			strategy: p.get_default('strategy', 'wrr')!
		)!

		action.done = true
	}
}

fn play_middlewares(mut plbook PlayBook, mut manager TraefikManager) ! {
	middleware_actions := plbook.find(filter: 'traefik.middleware')!

	for mut action in middleware_actions {
		mut p := action.params

		// Build settings map from remaining parameters
		mut settings := map[string]string{}

		middleware_type := p.get('type')!

		// Handle common middleware types
		match middleware_type {
			'basicAuth' {
				if users := p.get_default('users', '') {
					settings['users'] = '["${users}"]'
				}
			}
			'stripPrefix' {
				if prefixes := p.get_default('prefixes', '') {
					settings['prefixes'] = '["${prefixes}"]'
				}
			}
			'addPrefix' {
				if prefix := p.get_default('prefix', '') {
					settings['prefix'] = prefix
				}
			}
			'headers' {
				if custom_headers := p.get_default('customRequestHeaders', '') {
					settings['customRequestHeaders'] = custom_headers
				}
				if custom_response_headers := p.get_default('customResponseHeaders', '') {
					settings['customResponseHeaders'] = custom_response_headers
				}
			}
			'rateLimit' {
				if rate := p.get_default('rate', '') {
					settings['rate'] = rate
				}
				if burst := p.get_default('burst', '') {
					settings['burst'] = burst
				}
			}
			else {
				// For other middleware types, get all parameters as settings
				param_map := p.get_map()
				for key, value in param_map {
					if key !in ['name', 'type'] {
						settings[key] = value
					}
				}
			}
		}

		manager.middleware_add(
			name:     p.get('name')!
			typ:      middleware_type
			settings: settings
		)!

		action.done = true
	}
}
