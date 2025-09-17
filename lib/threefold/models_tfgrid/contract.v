module models_tfgrid

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Contract - ROOT OBJECT
@[heap]
pub struct Contract {
	db.Base
pub mut:
	customer_id           u32                         // links back to customer for this capacity
	compute_slices        []ComputeSliceProvisioned
	storage_slices        []StorageSliceProvisioned
	compute_slice_price   f64                         // price per 1 GB agreed upon
	storage_slice_price   f64                         // price per 1 GB agreed upon
	network_slice_price   f64                         // price per 1 GB agreed upon (transfer)
	status                ContractStatus
	start_date            u32                         // epoch
	end_date              u32
	signature_user        string                      // signature as done by user/consumer
	signature_hoster      string                      // signature as done by the hoster
	billing_period        BillingPeriod
}

pub enum ContractStatus {
	active
	cancelled
	error
	paused
}

// Provisioned compute slice
pub struct ComputeSliceProvisioned {
pub mut:
	node_id               u32
	id                    u16 // the id of the slice in the node
	mem_gb                f64
	storage_gb            f64
	passmark              int
	vcores                int
	cpu_oversubscription  int
	tags                  string
}

// Provisioned storage slice
pub struct StorageSliceProvisioned {
pub mut:
	node_id         u32
	id              u16 // the id of the slice in the node
	storage_size_gb int
	tags            string
}


pub struct DBContract {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Contract) type_name() string {
	return 'contract'
}

pub fn (self Contract) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a contract. Returns the ID of the contract.'
		}
		'get' {
			return 'Retrieve a contract by ID. Returns the contract object.'
		}
		'delete' {
			return 'Delete a contract by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a contract exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all contracts. Returns an array of contract objects.'
		}
		else {
			return 'Contract management methods for Grid4 infrastructure.'
		}
	}
}

pub fn (self Contract) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"contract": {"name": "contract-001", "customer_id": 456, "compute_slice_price": 0.05, "storage_slice_price": 0.01, "status": "active"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "contract-001", "customer_id": 456, "status": "active"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "contract-001", "customer_id": 456, "status": "active"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Contract) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.customer_id)
	
	// Encode compute slices
	e.add_int(self.compute_slices.len)
	for slice in self.compute_slices {
		e.add_u32(slice.node_id)
		e.add_u16(slice.id)
		e.add_f64(slice.mem_gb)
		e.add_f64(slice.storage_gb)
		e.add_int(slice.passmark)
		e.add_int(slice.vcores)
		e.add_int(slice.cpu_oversubscription)
		e.add_string(slice.tags)
	}
	
	// Encode storage slices
	e.add_int(self.storage_slices.len)
	for slice in self.storage_slices {
		e.add_u32(slice.node_id)
		e.add_u16(slice.id)
		e.add_int(slice.storage_size_gb)
		e.add_string(slice.tags)
	}
	
	e.add_f64(self.compute_slice_price)
	e.add_f64(self.storage_slice_price)
	e.add_f64(self.network_slice_price)
	e.add_int(int(self.status))
	e.add_u32(self.start_date)
	e.add_u32(self.end_date)
	e.add_string(self.signature_user)
	e.add_string(self.signature_hoster)
	e.add_int(int(self.billing_period))
}

fn (mut self DBContract) load(mut o Contract, mut e encoder.Decoder) ! {
	o.customer_id = e.get_u32()!
	
	// Decode compute slices
	compute_slices_len := e.get_int()!
	o.compute_slices = []ComputeSliceProvisioned{len: compute_slices_len}
	for i in 0 .. compute_slices_len {
		o.compute_slices[i].node_id = e.get_u32()!
		o.compute_slices[i].id = e.get_u16()!
		o.compute_slices[i].mem_gb = e.get_f64()!
		o.compute_slices[i].storage_gb = e.get_f64()!
		o.compute_slices[i].passmark = e.get_int()!
		o.compute_slices[i].vcores = e.get_int()!
		o.compute_slices[i].cpu_oversubscription = e.get_int()!
		o.compute_slices[i].tags = e.get_string()!
	}
	
	// Decode storage slices
	storage_slices_len := e.get_int()!
	o.storage_slices = []StorageSliceProvisioned{len: storage_slices_len}
	for i in 0 .. storage_slices_len {
		o.storage_slices[i].node_id = e.get_u32()!
		o.storage_slices[i].id = e.get_u16()!
		o.storage_slices[i].storage_size_gb = e.get_int()!
		o.storage_slices[i].tags = e.get_string()!
	}
	
	o.compute_slice_price = e.get_f64()!
	o.storage_slice_price = e.get_f64()!
	o.network_slice_price = e.get_f64()!
	o.status = unsafe { ContractStatus(e.get_int()!) }
	o.start_date = e.get_u32()!
	o.end_date = e.get_u32()!
	o.signature_user = e.get_string()!
	o.signature_hoster = e.get_string()!
	o.billing_period = unsafe { BillingPeriod(e.get_int()!) }
}

@[params]
pub struct ContractArg {
pub mut:
	name                  string
	description           string
	customer_id           u32
	compute_slices        []ComputeSliceProvisioned
	storage_slices        []StorageSliceProvisioned
	compute_slice_price   f64
	storage_slice_price   f64
	network_slice_price   f64
	status                ContractStatus
	start_date            u32
	end_date              u32
	signature_user        string
	signature_hoster      string
	billing_period        BillingPeriod
}

pub fn (mut self DBContract) new(args ContractArg) !Contract {
	mut o := Contract{
		customer_id:         args.customer_id
		compute_slices:      args.compute_slices
		storage_slices:      args.storage_slices
		compute_slice_price: args.compute_slice_price
		storage_slice_price: args.storage_slice_price
		network_slice_price: args.network_slice_price
		status:              args.status
		start_date:          args.start_date
		end_date:            args.end_date
		signature_user:      args.signature_user
		signature_hoster:    args.signature_hoster
		billing_period:      args.billing_period
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBContract) set(o Contract) !Contract {
	return self.db.set[Contract](o)!
}

pub fn (mut self DBContract) delete(id u32) ! {
	self.db.delete[Contract](id)!
}

pub fn (mut self DBContract) exist(id u32) !bool {
	return self.db.exists[Contract](id)!
}

pub fn (mut self DBContract) get(id u32) !Contract {
	mut o, data := self.db.get_data[Contract](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBContract) list() ![]Contract {
	return self.db.list[Contract]()!.map(self.get(it)!)
}