module herocluster

import incubaid.herolib.core.redisclient
import crypto.ed25519
import encoding.hex
import time

const election_timeout_ms = 3000
const heartbeat_interval_ms = 1000
const node_unavailable_threshold_ms = 24 * 60 * 60 * 1000 // 1 day in milliseconds
const health_check_interval_ms = 30000 // 30 seconds

// --- Crypto helpers ---

pub struct Keys {
pub mut:
	priv ed25519.PrivateKey
	pub  ed25519.PublicKey
}

// sign a message
fn (k Keys) sign(msg string) string {
	sig := ed25519.sign(k.priv, msg.bytes()) or { panic('Failed to sign message: ${err}') }
	return hex.encode(sig)
}

// verify signature
fn verify(pubkey ed25519.PublicKey, msg string, sig_hex string) bool {
	sig := hex.decode(sig_hex) or { return false }
	return ed25519.verify(pubkey, msg.bytes(), sig) or { false }
}

// --- Node & Election ---

pub enum NodeStatus {
	active
	buffer
	unavailable
}

pub struct Node {
pub:
	id string
pub mut:
	term      int
	leader    bool
	voted_for string
	status    NodeStatus
	last_seen i64 // timestamp
}

struct HealthReport {
	reporter_id string
	target_id   string
	status      string // "available" or "unavailable"
	timestamp   i64
	signature   string
}

pub struct Election {
pub mut:
	clients      []&redisclient.Redis
	pubkeys      map[string]ed25519.PublicKey
	self         Node
	keys         Keys
	all_nodes    map[string]Node
	buffer_nodes []string
}

// Redis keys
fn vote_key(term int, node_id string) string {
	return 'vote:${term}:${node_id}'
}

fn health_key(reporter_id string, target_id string) string {
	return 'health:${reporter_id}:${target_id}'
}

fn node_status_key(node_id string) string {
	return 'node_status:${node_id}'
}

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
	println('[${e.self.id}] voted for ${candidate} (term=${e.self.term})')
}

// Report node health status
fn (mut e Election) report_node_health(target_id string, status string) {
	now := time.now().unix()
	msg := '${target_id}:${status}:${now}'
	sig_hex := e.keys.sign(msg)

	_ := HealthReport{
		reporter_id: e.self.id
		target_id:   target_id
		status:      status
		timestamp:   now
		signature:   sig_hex
	}

	for mut c in e.clients {
		k := health_key(e.self.id, target_id)
		c.hset(k, 'status', status) or {}
		c.hset(k, 'timestamp', now.str()) or {}
		c.hset(k, 'signature', sig_hex) or {}
		c.expire(k, 86400) or {} // expire after 24 hours
	}
	println('[${e.self.id}] reported ${target_id} as ${status}')
}

// Collect health reports and check for consensus on unavailable nodes
fn (mut e Election) check_node_availability() {
	now := time.now().unix()
	mut unavailable_reports := map[string]map[string]i64{} // target_id -> reporter_id -> timestamp

	for mut c in e.clients {
		keys := c.keys('health:*') or { continue }
		for k in keys {
			parts := k.split(':')
			if parts.len != 3 {
				continue
			}
			reporter_id := parts[1]
			target_id := parts[2]

			vals := c.hgetall(k) or { continue }
			status := vals['status']
			timestamp_str := vals['timestamp']
			sig_hex := vals['signature']

			if reporter_id !in e.pubkeys {
				continue
			}

			timestamp := timestamp_str.i64()
			msg := '${target_id}:${status}:${timestamp}'

			if verify(e.pubkeys[reporter_id], msg, sig_hex) {
				if status == 'unavailable'
					&& (now - timestamp) >= (node_unavailable_threshold_ms / 1000) {
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
				println('[${e.self.id}] Consensus reached: ${target_id} is unavailable for >1 day')
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
		c.hset(k, 'promoted_at', time.now().unix().str()) or {}
		c.hset(k, 'replaced_node', failed_node_id) or {}

		// Mark failed node as unavailable
		failed_k := node_status_key(failed_node_id)
		c.hset(failed_k, 'status', 'unavailable') or {}
		c.hset(failed_k, 'failed_at', time.now().unix().str()) or {}
	}

	println('[${e.self.id}] Promoted buffer node ${buffer_id} to replace failed node ${failed_node_id}')
}

// Collect votes from ALL redis servers, verify signatures (only from active nodes)
fn (mut e Election) collect_votes(term int) map[string]int {
	mut counts := map[string]int{}
	mut seen := map[string]bool{} // avoid double-counting same vote from multiple servers

	for mut c in e.clients {
		keys := c.keys('vote:${term}:*') or { continue }
		for k in keys {
			if seen[k] {
				continue
			}
			seen[k] = true
			vals := c.hgetall(k) or { continue }
			candidate := vals['candidate']
			sig_hex := vals['sig']
			voter_id := k.split(':')[2]

			// Only count votes from active nodes
			if voter_id !in e.pubkeys || voter_id !in e.all_nodes {
				continue
			}
			if e.all_nodes[voter_id].status != .active {
				continue
			}

			msg := '${term}:${candidate}'
			if verify(e.pubkeys[voter_id], msg, sig_hex) {
				counts[candidate]++
			} else {
				println('[${e.self.id}] invalid signature from ${voter_id}')
			}
		}
	}
	return counts
}

// Run election (only active nodes participate)
fn (mut e Election) run_election() {
	if e.self.status != .active {
		return
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
				println('[${e.self.id}] I AM LEADER (term=${e.self.term}, votes=${cnt}, active_nodes=${active_node_count})')
				e.self.leader = true
			} else {
				println('[${e.self.id}] sees LEADER = ${cand} (term=${e.self.term}, votes=${cnt}, active_nodes=${active_node_count})')
				e.self.leader = false
			}
		}
	}
}

// Health monitoring loop (runs in background)
pub fn (mut e Election) health_monitor_loop() {
	for {
		if e.self.status == .active {
			// Check health of other nodes
			for node_id, _ in e.all_nodes {
				if node_id == e.self.id {
					continue
				}

				// Simple health check: try to read a heartbeat key
				mut is_available := false
				for mut c in e.clients {
					heartbeat_key := 'heartbeat:${node_id}'
					val := c.get(heartbeat_key) or { continue }
					last_heartbeat := val.i64()
					if (time.now().unix() - last_heartbeat) < 60 { // 60 seconds threshold
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
pub fn (mut e Election) heartbeat_loop() {
	for {
		// Update own heartbeat
		now := time.now().unix()
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
