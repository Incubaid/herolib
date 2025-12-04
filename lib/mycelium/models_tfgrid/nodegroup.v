module models_tfgrid

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db

// NodeGroup - ROOT OBJECT
@[heap]
pub struct NodeGroup {
	db.Base
pub mut:
	farmerid                            u32    // link back to farmer who owns the nodegroup
	secret                              string // only visible by farmer, in future encrypted, used to boot a node
	slapolicy                           SLAPolicy
	pricingpolicy                       PricingPolicy
	compute_slice_normalized_pricing_cc f64    // pricing in CC - cloud credit, per 2GB node slice
	storage_slice_normalized_pricing_cc f64    // pricing in CC - cloud credit, per 1GB storage slice
	signature_farmer                    string // signature as done by farmers to validate that they created this group
}

pub struct DBNodeGroup {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self NodeGroup) type_name() string {
	return 'nodegroup'
}

pub fn (self NodeGroup) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a node group. Returns the ID of the node group.'
		}
		'get' {
			return 'Retrieve a node group by ID. Returns the node group object.'
		}
		'delete' {
			return 'Delete a node group by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a node group exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all node groups. Returns an array of node group objects.'
		}
		else {
			return 'Node group management methods for Grid4 infrastructure.'
		}
	}
}

pub fn (self NodeGroup) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"nodegroup": {"name": "farmer-group-1", "farmerid": 123, "compute_slice_normalized_pricing_cc": 0.05, "storage_slice_normalized_pricing_cc": 0.01}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "farmer-group-1", "farmerid": 123, "compute_slice_normalized_pricing_cc": 0.05}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "farmer-group-1", "farmerid": 123, "compute_slice_normalized_pricing_cc": 0.05}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self NodeGroup) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.farmerid)
	e.add_string(self.secret)
	e.add_f32(self.slapolicy.uptime)
	e.add_u32(self.slapolicy.max_response_time_ms)
	e.add_int(self.slapolicy.sla_bandwidth_mbit)
	e.add_int(self.slapolicy.sla_penalty)
	e.add_string(self.pricingpolicy.name)
	e.add_string(self.pricingpolicy.details)
	e.add_list_int(self.pricingpolicy.marketplace_year_discounts)
	e.add_f64(self.compute_slice_normalized_pricing_cc)
	e.add_f64(self.storage_slice_normalized_pricing_cc)
	e.add_string(self.signature_farmer)
}

fn (mut self DBNodeGroup) load(mut o NodeGroup, mut e encoder.Decoder) ! {
	o.farmerid = e.get_u32()!
	o.secret = e.get_string()!
	o.slapolicy.uptime = e.get_f32()!
	o.slapolicy.max_response_time_ms = e.get_u32()!
	o.slapolicy.sla_bandwidth_mbit = e.get_int()!
	o.slapolicy.sla_penalty = e.get_int()!
	o.pricingpolicy.name = e.get_string()!
	o.pricingpolicy.details = e.get_string()!
	o.pricingpolicy.marketplace_year_discounts = e.get_list_int()!
	o.compute_slice_normalized_pricing_cc = e.get_f64()!
	o.storage_slice_normalized_pricing_cc = e.get_f64()!
	o.signature_farmer = e.get_string()!
}

@[params]
pub struct NodeGroupArg {
pub mut:
	name                                string
	description                         string
	farmerid                            u32
	secret                              string
	slapolicy                           SLAPolicy
	pricingpolicy                       PricingPolicy
	compute_slice_normalized_pricing_cc f64
	storage_slice_normalized_pricing_cc f64
	signature_farmer                    string
}

pub fn (mut self DBNodeGroup) new(args NodeGroupArg) !NodeGroup {
	mut o := NodeGroup{
		farmerid:                            args.farmerid
		secret:                              args.secret
		slapolicy:                           args.slapolicy
		pricingpolicy:                       args.pricingpolicy
		compute_slice_normalized_pricing_cc: args.compute_slice_normalized_pricing_cc
		storage_slice_normalized_pricing_cc: args.storage_slice_normalized_pricing_cc
		signature_farmer:                    args.signature_farmer
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBNodeGroup) set(o NodeGroup) !NodeGroup {
	return self.db.set[NodeGroup](o)!
}

pub fn (mut self DBNodeGroup) delete(id u32) ! {
	self.db.delete[NodeGroup](id)!
}

pub fn (mut self DBNodeGroup) exist(id u32) !bool {
	return self.db.exists[NodeGroup](id)!
}

pub fn (mut self DBNodeGroup) get(id u32) !NodeGroup {
	mut o, data := self.db.get_data[NodeGroup](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBNodeGroup) list() ![]NodeGroup {
	return self.db.list[NodeGroup]()!.map(self.get(it)!)
}
