module models_tfgrid

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Individual node reputation information
pub struct NodeReputation {
pub mut:
	node_id    u32
	reputation int = 50 // between 0 and 100, earned over time
	uptime     int      // between 0 and 100, set by system
}

// NodeGroupReputation - ROOT OBJECT
@[heap]
pub struct NodeGroupReputation {
	db.Base
pub mut:
	nodegroup_id u32
	reputation   int = 50            // between 0 and 100, earned over time
	uptime       int                 // between 0 and 100, set by system, farmer has no ability to set this
	nodes        []NodeReputation
}

pub struct DBNodeGroupReputation {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self NodeGroupReputation) type_name() string {
	return 'nodegroupreputation'
}

pub fn (self NodeGroupReputation) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update node group reputation. Returns the ID.'
		}
		'get' {
			return 'Retrieve node group reputation by ID. Returns the reputation object.'
		}
		'delete' {
			return 'Delete node group reputation by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if node group reputation exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all node group reputations. Returns an array of reputation objects.'
		}
		else {
			return 'Reputation management methods for Grid4 node groups.'
		}
	}
}

pub fn (self NodeGroupReputation) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"reputation": {"name": "group-1-reputation", "nodegroup_id": 1, "reputation": 85, "uptime": 99}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "group-1-reputation", "nodegroup_id": 1, "reputation": 85, "uptime": 99}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "group-1-reputation", "nodegroup_id": 1, "reputation": 85, "uptime": 99}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self NodeGroupReputation) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.nodegroup_id)
	e.add_int(self.reputation)
	e.add_int(self.uptime)
	
	// Encode node reputations
	e.add_int(self.nodes.len)
	for node in self.nodes {
		e.add_u32(node.node_id)
		e.add_int(node.reputation)
		e.add_int(node.uptime)
	}
}

fn (mut self DBNodeGroupReputation) load(mut o NodeGroupReputation, mut e encoder.Decoder) ! {
	o.nodegroup_id = e.get_u32()!
	o.reputation = e.get_int()!
	o.uptime = e.get_int()!
	
	// Decode node reputations
	nodes_len := e.get_int()!
	o.nodes = []NodeReputation{len: nodes_len}
	for i in 0 .. nodes_len {
		o.nodes[i].node_id = e.get_u32()!
		o.nodes[i].reputation = e.get_int()!
		o.nodes[i].uptime = e.get_int()!
	}
}

@[params]
pub struct NodeGroupReputationArg {
pub mut:
	name         string
	description  string
	nodegroup_id u32
	reputation   int = 50
	uptime       int
	nodes        []NodeReputation
}

pub fn (mut self DBNodeGroupReputation) new(args NodeGroupReputationArg) !NodeGroupReputation {
	mut o := NodeGroupReputation{
		nodegroup_id: args.nodegroup_id
		reputation:   args.reputation
		uptime:       args.uptime
		nodes:        args.nodes
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBNodeGroupReputation) set(o NodeGroupReputation) !NodeGroupReputation {
	return self.db.set[NodeGroupReputation](o)!
}

pub fn (mut self DBNodeGroupReputation) delete(id u32) ! {
	self.db.delete[NodeGroupReputation](id)!
}

pub fn (mut self DBNodeGroupReputation) exist(id u32) !bool {
	return self.db.exists[NodeGroupReputation](id)!
}

pub fn (mut self DBNodeGroupReputation) get(id u32) !NodeGroupReputation {
	mut o, data := self.db.get_data[NodeGroupReputation](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBNodeGroupReputation) list() ![]NodeGroupReputation {
	return self.db.list[NodeGroupReputation]()!.map(self.get(it)!)
}