# Hero Cluster Instructions v2: 4-Node Cluster with Buffer Node

This extends the **Redis + ed25519 leader election** from instruct1.md to include a **4th buffer node** mechanism for enhanced fault tolerance.

## Overview

* We have **4 Redis servers** (`:6379`, `:6380`, `:6381`, `:6382`).
* **3 active nodes** participate in normal leader election.
* **1 buffer node** remains standby and monitors the cluster health.
* If **2 of 3 active nodes** agree that a 3rd node is unavailable for **longer than 1 day**, the buffer node automatically becomes active.

---

## Extended V Implementation

```v
import db.redis
import crypto.ed25519
import crypto.rand
import encoding.hex
import os
import time

const election_timeout_ms = 3000
const heartbeat_interval_ms = 1000
const node_unavailable_threshold_ms = 24 * 60 * 60 * 1000 // 1 day in milliseconds
const health_check_interval_ms = 30000 // 30 seconds

// --- Crypto helpers ---

struct Keys {
    priv ed25519.PrivateKey
    pub  ed25519.PublicKey
}

// sign a message
fn (k Keys) sign(msg string) string {
    sig := ed25519.sign(k.priv, msg.bytes())
    return hex.encode(sig)
}

// verify signature
fn verify(pub ed25519.PublicKey, msg string, sig_hex string) bool {
    sig := hex.decode(sig_hex) or { return false }
    return ed25519.verify(pub, msg.bytes(), sig)
}

// --- Node & Election ---

enum NodeStatus {
    active
    buffer
    unavailable
}

struct Node {
    id    string
    mut:
        term      int
        leader    bool
        voted_for string
        status    NodeStatus
        last_seen i64 // timestamp
}

struct HealthReport {
    reporter_id   string
    target_id     string
    status        string // "available" or "unavailable"
    timestamp     i64
    signature     string
}

struct Election {
    mut:
        clients []redis.Connection
        pubkeys map[string]ed25519.PublicKey
        self    Node
        keys    Keys
        all_nodes map[string]Node
        buffer_nodes []string
}

// Redis keys
fn vote_key(term int, node_id string) string { return 'vote:${term}:${node_id}' }
fn health_key(reporter_id string, target_id string) string { return 'health:${reporter_id}:${target_id}' }
fn node_status_key(node_id string) string { return 'node_status:${node_id}' }

// Write vote (signed) to ALL redis servers
fn (mut e Election) vote_for(candidate string) {
    msg := '${e.self.term}:${candidate}'
    sig_hex := e.keys.sign(msg)
    for mut c in e.clients {
        k := vote_key(e.self.term, e.self.id)
        c.hset(k, 'candidate', candidate) or {}
        c.hset(k, 'sig', sig_hex) or {}
        c.expire(k, 5) or {}
    }
    println('[${e.self.id}] voted for $candidate (term=${e.self.term})')
}

// Report node health status
fn (mut e Election) report_node_health(target_id string, status string) {
    now := time.now().unix_time()
    msg := '${target_id}:${status}:${now}'
    sig_hex := e.keys.sign(msg)
    
    report := HealthReport{
        reporter_id: e.self.id
        target_id: target_id
        status: status
        timestamp: now
        signature: sig_hex
    }
    
    for mut c in e.clients {
        k := health_key(e.self.id, target_id)
        c.hset(k, 'status', status) or {}
        c.hset(k, 'timestamp', now.str()) or {}
        c.hset(k, 'signature', sig_hex) or {}
        c.expire(k, 86400) or {} // expire after 24 hours
    }
    println('[${e.self.id}] reported $target_id as $status')
}

// Collect health reports and check for consensus on unavailable nodes
fn (mut e Election) check_node_availability() {
    now := time.now().unix_time()
    mut unavailable_reports := map[string]map[string]i64{} // target_id -> reporter_id -> timestamp
    
    for mut c in e.clients {
        keys := c.keys('health:*') or { continue }
        for k in keys {
            parts := k.split(':')
            if parts.len != 3 { continue }
            reporter_id := parts[1]
            target_id := parts[2]
            
            vals := c.hgetall(k) or { continue }
            status := vals['status']
            timestamp_str := vals['timestamp']
            sig_hex := vals['signature']
            
            if reporter_id !in e.pubkeys { continue }
            
            timestamp := timestamp_str.i64()
            msg := '${target_id}:${status}:${timestamp}'
            
            if verify(e.pubkeys[reporter_id], msg, sig_hex) {
                if status == 'unavailable' && (now - timestamp) >= (node_unavailable_threshold_ms / 1000) {
                    if target_id !in unavailable_reports {
                        unavailable_reports[target_id] = map[string]i64{}
                    }
                    unavailable_reports[target_id][reporter_id] = timestamp
                }
            }
        }
    }
    
    // Check for consensus (2 out of 3 active nodes agree)
    for target_id, reports in unavailable_reports {
        if reports.len >= 2 && target_id in e.all_nodes {
            if e.all_nodes[target_id].status == .active {
                println('[${e.self.id}] Consensus reached: $target_id is unavailable for >1 day')
                e.promote_buffer_node(target_id)
            }
        }
    }
}

// Promote a buffer node to active status
fn (mut e Election) promote_buffer_node(failed_node_id string) {
    if e.buffer_nodes.len == 0 {
        println('[${e.self.id}] No buffer nodes available for promotion')
        return
    }
    
    // Select first available buffer node
    buffer_id := e.buffer_nodes[0]
    
    // Update node statuses
    if failed_node_id in e.all_nodes {
        e.all_nodes[failed_node_id].status = .unavailable
    }
    if buffer_id in e.all_nodes {
        e.all_nodes[buffer_id].status = .active
    }
    
    // Remove from buffer list
    e.buffer_nodes = e.buffer_nodes.filter(it != buffer_id)
    
    // Announce the promotion
    for mut c in e.clients {
        k := node_status_key(buffer_id)
        c.hset(k, 'status', 'active') or {}
        c.hset(k, 'promoted_at', time.now().unix_time().str()) or {}
        c.hset(k, 'replaced_node', failed_node_id) or {}
        
        // Mark failed node as unavailable
        failed_k := node_status_key(failed_node_id)
        c.hset(failed_k, 'status', 'unavailable') or {}
        c.hset(failed_k, 'failed_at', time.now().unix_time().str()) or {}
    }
    
    println('[${e.self.id}] Promoted buffer node $buffer_id to replace failed node $failed_node_id')
}

// Collect votes from ALL redis servers, verify signatures (only from active nodes)
fn (mut e Election) collect_votes(term int) map[string]int {
    mut counts := map[string]int{}
    mut seen := map[string]bool{} // avoid double-counting same vote from multiple servers

    for mut c in e.clients {
        keys := c.keys('vote:${term}:*') or { continue }
        for k in keys {
            if seen[k] { continue }
            seen[k] = true
            vals := c.hgetall(k) or { continue }
            candidate := vals['candidate']
            sig_hex := vals['sig']
            voter_id := k.split(':')[2]
            
            // Only count votes from active nodes
            if voter_id !in e.pubkeys || voter_id !in e.all_nodes { continue }
            if e.all_nodes[voter_id].status != .active { continue }
            
            msg := '${term}:${candidate}'
            if verify(e.pubkeys[voter_id], msg, sig_hex) {
                counts[candidate]++
            } else {
                println('[${e.self.id}] invalid signature from $voter_id')
            }
        }
    }
    return counts
}

// Run election (only active nodes participate)
fn (mut e Election) run_election() {
    if e.self.status != .active {
        return // Buffer nodes don't participate in elections
    }
    
    e.self.term++
    e.vote_for(e.self.id)

    // wait a bit for other nodes to also vote
    time.sleep(500 * time.millisecond)

    votes := e.collect_votes(e.self.term)
    active_node_count := e.all_nodes.values().filter(it.status == .active).len
    majority_threshold := (active_node_count / 2) + 1
    
    for cand, cnt in votes {
        if cnt >= majority_threshold {
            if cand == e.self.id {
                println('[${e.self.id}] I AM LEADER (term=${e.self.term}, votes=$cnt, active_nodes=$active_node_count)')
                e.self.leader = true
            } else {
                println('[${e.self.id}] sees LEADER = $cand (term=${e.self.term}, votes=$cnt, active_nodes=$active_node_count)')
                e.self.leader = false
            }
        }
    }
}

// Health monitoring loop (runs in background)
fn (mut e Election) health_monitor_loop() {
    for {
        if e.self.status == .active {
            // Check health of other nodes
            for node_id, node in e.all_nodes {
                if node_id == e.self.id { continue }
                
                // Simple health check: try to read a heartbeat key
                mut is_available := false
                for mut c in e.clients {
                    heartbeat_key := 'heartbeat:${node_id}'
                    val := c.get(heartbeat_key) or { continue }
                    last_heartbeat := val.i64()
                    if (time.now().unix_time() - last_heartbeat) < 60 { // 60 seconds threshold
                        is_available = true
                        break
                    }
                }
                
                status := if is_available { 'available' } else { 'unavailable' }
                e.report_node_health(node_id, status)
            }
            
            // Check for consensus on failed nodes
            e.check_node_availability()
        }
        
        time.sleep(health_check_interval_ms * time.millisecond)
    }
}

// Heartbeat loop
fn (mut e Election) heartbeat_loop() {
    for {
        // Update own heartbeat
        now := time.now().unix_time()
        for mut c in e.clients {
            heartbeat_key := 'heartbeat:${e.self.id}'
            c.set(heartbeat_key, now.str()) or {}
            c.expire(heartbeat_key, 120) or {} // expire after 2 minutes
        }
        
        if e.self.status == .active {
            if e.self.leader {
                println('[${e.self.id}] Heartbeat term=${e.self.term} (LEADER)')
            } else {
                e.run_election()
            }
        } else if e.self.status == .buffer {
            println('[${e.self.id}] Buffer node monitoring cluster')
        }
        
        time.sleep(heartbeat_interval_ms * time.millisecond)
    }
}

// --- MAIN ---

fn main() {
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
}
```

---

## Key Extensions from instruct1.md

### 1. **4th Redis Server**
- Added `:6382` as the 4th Redis server for enhanced redundancy.

### 2. **Node Status Management**
- **NodeStatus enum**: `active`, `buffer`, `unavailable`
- **Buffer nodes**: Don't participate in elections but monitor cluster health.

### 3. **Health Monitoring System**
- **Health reports**: Signed reports about node availability.
- **Consensus mechanism**: 2 out of 3 active nodes must agree a node is unavailable.
- **1-day threshold**: Node must be unavailable for >24 hours before replacement.

### 4. **Automatic Buffer Promotion**
- When consensus is reached about a failed node, buffer node automatically becomes active.
- Failed node is marked as unavailable.
- Cluster continues with 3 active nodes.

### 5. **Enhanced Election Logic**
- Only active nodes participate in voting.
- Majority threshold adapts to current number of active nodes.
- Buffer nodes monitor but don't vote.

---

## How to Run

1. **Start 4 redis servers**:
   ```bash
   redis-server --port 6379 --dir /tmp/redis1 --daemonize yes
   redis-server --port 6380 --dir /tmp/redis2 --daemonize yes
   redis-server --port 6381 --dir /tmp/redis3 --daemonize yes
   redis-server --port 6382 --dir /tmp/redis4 --daemonize yes
   ```

2. **Run 3 active nodes + 1 buffer**:
   ```bash
   v run raft_sign_v2.v node1 active
   v run raft_sign_v2.v node2 active
   v run raft_sign_v2.v node3 active
   v run raft_sign_v2.v node4 buffer
   ```

3. **Test failure scenario**:
   - Stop one active node (e.g., kill node3)
   - Wait >1 day (or reduce threshold for testing)
   - Watch buffer node4 automatically become active
   - Cluster continues with 3 active nodes

---

## Benefits

- **Enhanced fault tolerance**: Can survive 1 node failure without service interruption.
- **Automatic recovery**: No manual intervention needed for node replacement.
- **Consensus-based decisions**: Prevents false positives in failure detection.
- **Cryptographic security**: All health reports are signed and verified.
- **Scalable design**: Easy to add more buffer nodes if needed.