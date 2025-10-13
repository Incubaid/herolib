#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import crypto.ed25519
import incubaid.herolib.core.base
import incubaid.herolib.core.redisclient
import incubaid.herolib.hero.herocluster
import os
import rand

mut ctx := base.context()!
redis := ctx.redis()!

if os.args.len < 3 {
	eprintln('Usage: ./prog <node_id> <status>')
	eprintln('  status: active|buffer')
	return
}
node_id := os.args[1]
status_str := os.args[2]

status := match status_str {
	'active' {
		herocluster.NodeStatus.active
	}
	'buffer' {
		herocluster.NodeStatus.buffer
	}
	else {
		eprintln('Invalid status. Use: active|buffer')
		return
	}
}

// --- Generate ephemeral keys for demo ---
// In real use: load from PEM files
pub_, priv := ed25519.generate_key()!

mut pubkeys := map[string]ed25519.PublicKey{}
pubkeys[node_id] = pub_
// TODO: load all pubkeys from config file so every node knows others

// Initialize all nodes (in real scenario, load from config)
mut all_nodes := map[string]herocluster.Node{}
all_nodes['node1'] = herocluster.Node{
	id:     'node1'
	status: .active
}
all_nodes['node2'] = herocluster.Node{
	id:     'node2'
	status: .active
}
all_nodes['node3'] = herocluster.Node{
	id:     'node3'
	status: .active
}
all_nodes['node4'] = herocluster.Node{
	id:     'node4'
	status: .buffer
}

// Set current node status
all_nodes[node_id].status = status

servers := ['127.0.0.1:6379', '127.0.0.1:6380', '127.0.0.1:6381', '127.0.0.1:6382']
mut conns := []&redisclient.Redis{}
for s in servers {
	redis_url := redisclient.get_redis_url(s) or {
		eprintln('Warning: could not parse redis url ${s}: ${err}')
		continue
	}
	mut c := redisclient.core_get(redis_url) or {
		eprintln('Warning: could not connect to redis ${s}: ${err}')
		continue
	}
	conns << c
	println('Connected to Redis server: ${s}')
}

if conns.len == 0 {
	eprintln('Error: No Redis servers available. Please start at least one Redis server.')
	return
}

mut election := &herocluster.Election{
	clients:      conns
	pubkeys:      pubkeys
	self:         herocluster.Node{
		id:     node_id
		term:   0
		leader: false
		status: status
	}
	keys:         herocluster.Keys{
		priv: priv
		pub:  pub_
	}
	all_nodes:    all_nodes
	buffer_nodes: ['node4'] // Initially node4 is buffer
}

println('[${node_id}] started as ${status_str}, connected to 4 redis servers.')

// Start health monitoring in background
spawn election.health_monitor_loop()

// Start main heartbeat loop
election.heartbeat_loop()
