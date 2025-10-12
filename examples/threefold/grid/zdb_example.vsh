#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.redisclient { RedisClient }

struct ZDBSpecs {
	deployment_name string
	nodeid          string
	namespace       string
	secret          string
}

struct ZDBDeployed {
	nodeid    string
	namespace string
	secret    string
	host      string
	port      int
}

// test zdb is answering
pub fn (zdb ZDBDeployed) ping() !bool {
	mut client := zdb.redisclient()!
	return client.ping()!
}

pub fn (zdb ZDBDeployed) redisclient() !RedisClient {
	return RedisClient.new(
		host:     zdb.host
		port:     zdb.port
		password: zdb.secret
		db:       0
	)!
}

// only connect to yggdrasil and mycelium
fn zdb_deploy(args ZDBSpecs) !ZDBDeployed {
	// Implementation would need to:
	// 1. Deploy ZDB on the specified node
	// 2. Configure namespace and security
	// 3. Return connection details
	return ZDBDeployed{
		nodeid:    args.nodeid
		namespace: args.namespace
		secret:    args.secret
		host:      '' // Would be set to actual host
		port:      0  // Would be set to actual port
	}
}
