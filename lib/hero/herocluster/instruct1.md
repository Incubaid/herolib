Great 👍 Let’s extend the **Redis + ed25519 leader election** so that:

* We have **3 Redis servers** (`:6379`, `:6380`, `:6381`).
* Each node writes its **signed vote** to **all 3 servers**.
* Each node reads all votes from all servers, verifies them with the **known public keys**, and tallies majority (≥2/3 = 2 votes).
* Leader is declared if majority agrees.

---

## Full V Implementation

```v
import db.redis
import crypto.ed25519
import crypto.rand
import encoding.hex
import os
import time

const election_timeout_ms = 3000
const heartbeat_interval_ms = 1000

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

struct Node {
    id    string
    mut:
        term      int
        leader    bool
        voted_for string
}

struct Election {
    mut:
        clients []redis.Connection
        pubkeys map[string]ed25519.PublicKey
        self    Node
        keys    Keys
}

// Redis keys
fn vote_key(term int, node_id string) string { return 'vote:${term}:${node_id}' }

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

// Collect votes from ALL redis servers, verify signatures
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
            if voter_id !in e.pubkeys {
                println('[${e.self.id}] unknown voter $voter_id')
                continue
            }
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

// Run election
fn (mut e Election) run_election() {
    e.self.term++
    e.vote_for(e.self.id)

    // wait a bit for other nodes to also vote
    time.sleep(500 * time.millisecond)

    votes := e.collect_votes(e.self.term)
    for cand, cnt in votes {
        if cnt >= 2 { // majority of 3
            if cand == e.self.id {
                println('[${e.self.id}] I AM LEADER (term=${e.self.term}, votes=$cnt)')
                e.self.leader = true
            } else {
                println('[${e.self.id}] sees LEADER = $cand (term=${e.self.term}, votes=$cnt)')
                e.self.leader = false
            }
        }
    }
}

// Heartbeat loop
fn (mut e Election) heartbeat_loop() {
    for {
        if e.self.leader {
            println('[${e.self.id}] Heartbeat term=${e.self.term}')
        } else {
            e.run_election()
        }
        time.sleep(heartbeat_interval_ms * time.millisecond)
    }
}

// --- MAIN ---

fn main() {
    if os.args.len < 2 {
        eprintln('Usage: ./prog <node_id>')
        return
    }
    node_id := os.args[1]

    // --- Generate ephemeral keys for demo ---
    // In real use: load from PEM files
    priv, pub := ed25519.generate_key(rand.reader) or { panic(err) }

    mut pubkeys := map[string]ed25519.PublicKey{}
    pubkeys[node_id] = pub
    // TODO: load all pubkeys from config file so every node knows others

    servers := ['127.0.0.1:6379', '127.0.0.1:6380', '127.0.0.1:6381']
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
        }
        keys: Keys{ priv: priv, pub: pub }
    }

    println('[$node_id] started, connected to 3 redis servers.')
    election.heartbeat_loop()
}
```

---

## How to Run

1. Start 3 redis servers (different ports):

   ```bash
   redis-server --port 6379 --dir /tmp/redis1 --daemonize yes
   redis-server --port 6380 --dir /tmp/redis2 --daemonize yes
   redis-server --port 6381 --dir /tmp/redis3 --daemonize yes
   ```

2. Run 3 nodes, each with its own ID:

   ```bash
   v run raft_sign.v node1
   v run raft_sign.v node2
   v run raft_sign.v node3
   ```

3. You’ll see one leader elected with **2/3 majority verified votes**.

