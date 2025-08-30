#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

if os.args.len < 3 {
    eprintln('Usage: ./prog <node_id> <status>')
    eprintln('  status: active|buffer')
    return
}
node_id := os.args[1]
status_str := os.args[2]

status := match status_str {
    'active' { NodeStatus.active }
    'buffer' { NodeStatus.buffer }
    else { 
        eprintln('Invalid status. Use: active|buffer')
        return
    }
}

// --- Generate ephemeral keys for demo ---
// In real use: load from PEM files
priv, pub := ed25519.generate_key(rand.reader) or { panic(err) }

mut pubkeys := map[string]ed25519.PublicKey{}
pubkeys[node_id] = pub
// TODO: load all pubkeys from config file so every node knows others

// Initialize all nodes (in real scenario, load from config)
mut all_nodes := map[string]Node{}
all_nodes['node1'] = Node{id: 'node1', status: .active}
all_nodes['node2'] = Node{id: 'node2', status: .active}
all_nodes['node3'] = Node{id: 'node3', status: .active}
all_nodes['node4'] = Node{id: 'node4', status: .buffer}

// Set current node status
all_nodes[node_id].status = status

servers := ['127.0.0.1:6379', '127.0.0.1:6380', '127.0.0.1:6381', '127.0.0.1:6382']
mut conns := []redis.Connection{}
for s in servers {
    mut c := redis.connect(redis.Options{ server: s }) or {
        panic('could not connect to redis $s: $err')
    }
    conns << c
}

mut election := Election{
    clients: conns
    pubkeys: pubkeys
    self: Node{
        id: node_id
        term: 0
        leader: false
        status: status
    }
    keys: Keys{ priv: priv, pub: pub }
    all_nodes: all_nodes
    buffer_nodes: ['node4'] // Initially node4 is buffer
}

println('[$node_id] started as $status_str, connected to 4 redis servers.')

// Start health monitoring in background
go election.health_monitor_loop()

// Start main heartbeat loop
election.heartbeat_loop()
