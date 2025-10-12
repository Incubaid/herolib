module models_tfgrid

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db
import incubaid.herolib.data.json

// Bid - ROOT OBJECT
@[heap]
pub struct Bid {
	db.Base
pub mut:
	customer_id    u32               // links back to customer for this capacity (user on ledger)
	requirements   map[string]string // e.g. compute_nodes:10, certified:true
	pricing        map[string]string // e.g. compute_nodes:10.2 (price per unit), certified_CU: 100.3 (price per CU)
	status         BidStatus
	obligation     bool // if obligation then will be charged and money needs to be in escrow
	start_date     u32  // epoch
	end_date       u32
	signature_user string // signature as done by a user/consumer to validate their identity and intent
	billing_period BillingPeriod
}

pub enum BidStatus {
	pending
	confirmed
	assigned
	cancelled
	done
}

pub enum BillingPeriod {
	hourly
	monthly
	yearly
	biannually
	triannually
}

pub struct DBBid {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Bid) type_name() string {
	return 'bid'
}

pub fn (self Bid) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a bid. Returns the ID of the bid.'
		}
		'get' {
			return 'Retrieve a bid by ID. Returns the bid object.'
		}
		'delete' {
			return 'Delete a bid by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a bid exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all bids. Returns an array of bid objects.'
		}
		else {
			return 'Bid management methods for Grid4 infrastructure.'
		}
	}
}

pub fn (self Bid) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"bid": {"name": "compute-bid-1", "customer_id": 456, "requirements": {"compute_slices":10}, "pricing": {"compute_slices":10.2}, "status": "pending", "obligation": true}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "compute-bid-1", "customer_id": 456, "requirements": {"compute_slices":10}, "status": "pending"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "compute-bid-1", "customer_id": 456, "status": "pending"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Bid) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.customer_id)
	e.add_string(json.encode(self.requirements))
	e.add_string(json.encode(self.pricing))
	e.add_int(int(self.status))
	e.add_bool(self.obligation)
	e.add_u32(self.start_date)
	e.add_u32(self.end_date)
	e.add_string(self.signature_user)
	e.add_int(int(self.billing_period))
}

fn (mut self DBBid) load(mut o Bid, mut e encoder.Decoder) ! {
	o.customer_id = e.get_u32()!
	o.requirements = json.decode[map[string]string](e.get_string()!)!
	o.pricing = json.decode[map[string]string](e.get_string()!)!
	o.status = unsafe { BidStatus(e.get_int()!) }
	o.obligation = e.get_bool()!
	o.start_date = e.get_u32()!
	o.end_date = e.get_u32()!
	o.signature_user = e.get_string()!
	o.billing_period = unsafe { BillingPeriod(e.get_int()!) }
}

@[params]
pub struct BidArg {
pub mut:
	name           string
	description    string
	customer_id    u32
	requirements   map[string]string
	pricing        map[string]string
	status         BidStatus
	obligation     bool
	start_date     u32
	end_date       u32
	signature_user string
	billing_period BillingPeriod
}

pub fn (mut self DBBid) new(args BidArg) !Bid {
	mut o := Bid{
		customer_id:    args.customer_id
		requirements:   args.requirements
		pricing:        args.pricing
		status:         args.status
		obligation:     args.obligation
		start_date:     args.start_date
		end_date:       args.end_date
		signature_user: args.signature_user
		billing_period: args.billing_period
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBBid) set(o Bid) !Bid {
	return self.db.set[Bid](o)!
}

pub fn (mut self DBBid) delete(id u32) ! {
	self.db.delete[Bid](id)!
}

pub fn (mut self DBBid) exist(id u32) !bool {
	return self.db.exists[Bid](id)!
}

pub fn (mut self DBBid) get(id u32) !Bid {
	mut o, data := self.db.get_data[Bid](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBBid) list() ![]Bid {
	return self.db.list[Bid]()!.map(self.get(it)!)
}
