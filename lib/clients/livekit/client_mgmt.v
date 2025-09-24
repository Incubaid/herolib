module livekit

import freeflowuniverse.herolib.data.caching
import os

// const CACHING_METHOD = caching.CachingMethod.once_per_process

fn _init() ! {
	if caching.is_set(key: 'livekit_clients') {
		return
	}
	caching.set[map[string]LivekitClient](
		key: 'livekit_clients'
		val: map[string]LivekitClient{}
	)!
}

fn _get() !map[string]LivekitClient {
	_init()!
	return caching.get[map[string]LivekitClient](key: 'livekit_clients')!
}

pub fn get(name string) !LivekitClient {
	mut clients := _get()!
	return clients[name] or { return error('livekit client ${name} not found') }
}

pub fn set(client LivekitClient) ! {
	mut clients := _get()!
	clients[client.name] = client
	caching.set[map[string]LivekitClient](key: 'livekit_clients', val: clients)!
}

pub fn exists(name string) !bool {
	mut clients := _get()!
	return name in clients
}
