module docker

import incubaid.herolib.crypt.openssl
import incubaid.herolib.core.httpconnection
import incubaid.herolib.osal.core as osal
import os
import incubaid.herolib.ui.console

@[heap]
pub struct DockerRegistry {
pub mut:
	name     string = 'default'
	datapath string
	ssl      bool
}

@[params]
pub struct DockerRegistryArgs {
pub mut:
	name      string = 'default' @[required]
	datapath  string
	ssl       bool
	reset     bool // if reset will reset existing running one
	reset_ssl bool // if reset will reset the sslkey
	secret    string = '1234' @[required]
}

// registry:
//   restart: always
//   image: registry:2
//   ports:
//     - 5000:5000
//   environment:
//     REGISTRY_HTTP_TLS_CERTIFICATE: /certs/domain.crt
//     REGISTRY_HTTP_TLS_KEY: /certs/domain.key
//     REGISTRY_AUTH: htpasswd
//     REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
//     REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
//   volumes:
//     - ${registry.datapath}/data:/var/lib/registry
//     - ${registry.datapath}/certs:/certs
//     - ${registry.datapath}/auth:/auth

// check docker has been installed & enabled on node
pub fn (mut e DockerEngine) registry_add(args DockerRegistryArgs) ! {
	mut registry := DockerRegistry{
		name:     args.name
		datapath: args.datapath
		ssl:      args.ssl
	}

	if registry.datapath.len < 4 {
		return error('datapath needs to be len +3')
	}

	mut composer := e.compose_new(name: 'docker_registry')
	mut service := composer.service_new(name: 'registry', image: 'registry:2')!
	service.restart_set()
	service.port_expose(5000, 5000)!

	if registry.ssl {
		service.env_add('REGISTRY_HTTP_TLS_CERTIFICATE', '/certs/domain.crt')
		service.env_add('REGISTRY_HTTP_TLS_KEY', ' /certs/domain.key')
		service.env_add('REGISTRY_AUTH', 'htpasswd')
		service.env_add('REGISTRY_AUTH_HTPASSWD_PATH', '/auth/htpasswd')
		service.env_add('REGISTRY_AUTH_HTPASSWD_REALM', 'Registry Realm')
		service.env_add('REGISTRY_LOGLEVEL', 'debug')
		service.env_add('REGISTRY_HTTP_SECRET', args.secret)
		service.volume_add('${registry.datapath}/data', '/var/lib/registry')!
		service.volume_add('${registry.datapath}/certs', '/certs')!
		service.volume_add('${registry.datapath}/auth', '/auth')!

		p1 := '${registry.datapath}/certs/domain.crt'
		p2 := '${registry.datapath}/certs/domain.key'
		if !os.exists(p1) || !os.exists(p2) || args.reset_ssl {
			// means we are missing a key
			mut ossl := openssl.new()!
			k := ossl.get(name: 'docker_registry')!
			os.mkdir_all('${registry.datapath}/certs')!
			os.cp(k.path_cert.path, p1)!
			os.cp(k.path_key.path, p2)!
		}
	}
	e.registries << registry

	// delete all previous containers, uses wildcards see https://modules.vlang.io/index.html#string.match_glob

	e.container_delete(name: 'docker_registry*') or {
		if !(err as ContainerGetError).notfound {
			return err
		}
		println('No containers to matching docker registry')
	}

	composer.start()!

	mut conn := httpconnection.new(
		name:  'localdockerhub'
		url:   'https://localhost:5000/v2/'
		retry: 10
	)!

	res := conn.get()!
	println(res)
}
