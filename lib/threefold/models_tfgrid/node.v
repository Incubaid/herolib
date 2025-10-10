module models_tfgrid

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Storage device information
pub struct StorageDevice {
pub mut:
	id          string // can be used in node
	size_gb     f64    // Size of the storage device in gigabytes
	description string // Description of the storage device
}

// Memory device information
pub struct MemoryDevice {
pub mut:
	id          string // can be used in node
	size_gb     f64    // Size of the memory device in gigabytes
	description string // Description of the memory device
}

// CPU device information
pub struct CPUDevice {
pub mut:
	id          string // can be used in node
	cores       int    // Number of CPU cores
	passmark    int
	description string // Description of the CPU
	cpu_brand   string // Brand of the CPU
	cpu_version string // Version of the CPU
}

// GPU device information
pub struct GPUDevice {
pub mut:
	id          string // can be used in node
	cores       int    // Number of GPU cores
	memory_gb   f64    // Size of the GPU memory in gigabytes
	description string // Description of the GPU
	gpu_brand   string
	gpu_version string
}

// Network device information
pub struct NetworkDevice {
pub mut:
	id          string // can be used in node
	speed_mbps  int    // Network speed in Mbps
	description string // Description of the network device
}

// Aggregated device info for a node
pub struct DeviceInfo {
pub mut:
	vendor  string
	storage []StorageDevice
	memory  []MemoryDevice
	cpu     []CPUDevice
	gpu     []GPUDevice
	network []NetworkDevice
}

// NodeCapacity represents the hardware capacity details of a node
pub struct NodeCapacity {
pub mut:
	storage_gb f64 // Total storage in gigabytes
	mem_gb     f64 // Total memory in gigabytes
	mem_gb_gpu f64 // Total GPU memory in gigabytes
	passmark   int // Passmark score for the node
	vcores     int // Total virtual cores
}

// Pricing policy for slices
pub struct PricingPolicy {
pub mut:
	name                         string // Human friendly policy name (e.g. "fixed", "market")
	details                      string // Optional free-form details as JSON-encoded string
	marketplace_year_discounts   []int  // e.g. [30, 40, 50] means if user has more CC than 1Y utilization, 30% discount, etc.
}

// SLA policy for slices
pub struct SLAPolicy {
pub mut:
	uptime                 f32 // Uptime in percentage (0..100)
	max_response_time_ms   u32 // Max response time in ms
	sla_bandwidth_mbit     int // minimal mbits we can expect avg over 1h per node, 0 means we don't guarantee
	sla_penalty            int // 0-100, percent of money given back in relation to month if sla breached
}

// Compute slice (typically represents a base unit of compute)
pub struct ComputeSlice {
pub mut:
	id                       int // the id of the slice in the node
	mem_gb                   f64
	storage_gb               f64
	passmark                 int
	vcores                   int
	cpu_oversubscription     int
	storage_oversubscription int
	price_range              []f64 // Min/max allowed price range for validation
	gpus                     u8    // nr of GPU's see node to know what GPU's are
	price_cc                 f64   // price per slice in cloud credits
	pricing_policy           PricingPolicy
	sla_policy               SLAPolicy
}

// Storage slice (typically 1GB of storage)
pub struct StorageSlice {
pub mut:
	id             int // the id of the slice in the node
	price_cc       f64 // price per slice in cloud credits
	pricing_policy PricingPolicy
	sla_policy     SLAPolicy
}

// Grid4 Node model - ROOT OBJECT
@[heap]
pub struct Node {
	db.Base
pub mut:
	nodegroupid     int          // Link to node group
	uptime          int          // Uptime percentage 0..100
	computeslices   []ComputeSlice
	storageslices   []StorageSlice
	devices         DeviceInfo
	country         string       // 2 letter code
	capacity        NodeCapacity // Hardware capacity details
	birthtime       u32          // first time node was active
	pubkey          string
	signature_node  string       // signature done on node to validate pubkey with privkey
	signature_farmer string      // signature as done by farmers to validate their identity
}

pub struct DBNode {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Node) type_name() string {
	return 'node'
}

pub fn (self Node) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a node. Returns the ID of the node.'
		}
		'get' {
			return 'Retrieve a node by ID. Returns the node object.'
		}
		'delete' {
			return 'Delete a node by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a node exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all nodes. Returns an array of node objects.'
		}
		else {
			return 'Node management methods for Grid4 infrastructure.'
		}
	}
}

pub fn (self Node) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"node": {"name": "node-001", "nodegroupid": 1, "uptime": 99, "country": "BE", "devices": {"vendor": "Dell"}, "capacity": {"storage_gb": 1000, "mem_gb": 64, "vcores": 16, "passmark": 15000}}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "node-001", "nodegroupid": 1, "uptime": 99, "country": "BE"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "node-001", "nodegroupid": 1, "uptime": 99, "country": "BE"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Node) dump(mut e encoder.Encoder) ! {
	e.add_int(self.nodegroupid)
	e.add_int(self.uptime)
	
	// Encode compute slices
	e.add_int(self.computeslices.len)
	for slice in self.computeslices {
		e.add_int(slice.id)
		e.add_f64(slice.mem_gb)
		e.add_f64(slice.storage_gb)
		e.add_int(slice.passmark)
		e.add_int(slice.vcores)
		e.add_int(slice.cpu_oversubscription)
		e.add_int(slice.storage_oversubscription)
		e.add_list_f64(slice.price_range)
		e.add_u8(slice.gpus)
		e.add_f64(slice.price_cc)
		e.add_string(slice.pricing_policy.name)
		e.add_string(slice.pricing_policy.details)
		e.add_list_int(slice.pricing_policy.marketplace_year_discounts)
		e.add_f32(slice.sla_policy.uptime)
		e.add_u32(slice.sla_policy.max_response_time_ms)
		e.add_int(slice.sla_policy.sla_bandwidth_mbit)
		e.add_int(slice.sla_policy.sla_penalty)
	}
	
	// Encode storage slices
	e.add_int(self.storageslices.len)
	for slice in self.storageslices {
		e.add_int(slice.id)
		e.add_f64(slice.price_cc)
		e.add_string(slice.pricing_policy.name)
		e.add_string(slice.pricing_policy.details)
		e.add_list_int(slice.pricing_policy.marketplace_year_discounts)
		e.add_f32(slice.sla_policy.uptime)
		e.add_u32(slice.sla_policy.max_response_time_ms)
		e.add_int(slice.sla_policy.sla_bandwidth_mbit)
		e.add_int(slice.sla_policy.sla_penalty)
	}
	
	// Encode devices
	e.add_string(self.devices.vendor)
	e.add_int(self.devices.storage.len)
	for device in self.devices.storage {
		e.add_string(device.id)
		e.add_f64(device.size_gb)
		e.add_string(device.description)
	}
	e.add_int(self.devices.memory.len)
	for device in self.devices.memory {
		e.add_string(device.id)
		e.add_f64(device.size_gb)
		e.add_string(device.description)
	}
	e.add_int(self.devices.cpu.len)
	for device in self.devices.cpu {
		e.add_string(device.id)
		e.add_int(device.cores)
		e.add_int(device.passmark)
		e.add_string(device.description)
		e.add_string(device.cpu_brand)
		e.add_string(device.cpu_version)
	}
	e.add_int(self.devices.gpu.len)
	for device in self.devices.gpu {
		e.add_string(device.id)
		e.add_int(device.cores)
		e.add_f64(device.memory_gb)
		e.add_string(device.description)
		e.add_string(device.gpu_brand)
		e.add_string(device.gpu_version)
	}
	e.add_int(self.devices.network.len)
	for device in self.devices.network {
		e.add_string(device.id)
		e.add_int(device.speed_mbps)
		e.add_string(device.description)
	}
	
	e.add_string(self.country)
	e.add_f64(self.capacity.storage_gb)
	e.add_f64(self.capacity.mem_gb)
	e.add_f64(self.capacity.mem_gb_gpu)
	e.add_int(self.capacity.passmark)
	e.add_int(self.capacity.vcores)
	e.add_u32(self.birthtime)
	e.add_string(self.pubkey)
	e.add_string(self.signature_node)
	e.add_string(self.signature_farmer)
}

fn (mut self DBNode) load(mut o Node, mut e encoder.Decoder) ! {
	o.nodegroupid = e.get_int()!
	o.uptime = e.get_int()!
	
	// Decode compute slices
	compute_slices_len := e.get_int()!
	o.computeslices = []ComputeSlice{len: compute_slices_len}
	for i in 0 .. compute_slices_len {
		o.computeslices[i].id = e.get_int()!
		o.computeslices[i].mem_gb = e.get_f64()!
		o.computeslices[i].storage_gb = e.get_f64()!
		o.computeslices[i].passmark = e.get_int()!
		o.computeslices[i].vcores = e.get_int()!
		o.computeslices[i].cpu_oversubscription = e.get_int()!
		o.computeslices[i].storage_oversubscription = e.get_int()!
		o.computeslices[i].price_range = e.get_list_f64()!
		o.computeslices[i].gpus = e.get_u8()!
		o.computeslices[i].price_cc = e.get_f64()!
		o.computeslices[i].pricing_policy.name = e.get_string()!
		o.computeslices[i].pricing_policy.details = e.get_string()!
		o.computeslices[i].pricing_policy.marketplace_year_discounts = e.get_list_int()!
		o.computeslices[i].sla_policy.uptime = e.get_f32()!
		o.computeslices[i].sla_policy.max_response_time_ms = e.get_u32()!
		o.computeslices[i].sla_policy.sla_bandwidth_mbit = e.get_int()!
		o.computeslices[i].sla_policy.sla_penalty = e.get_int()!
	}
	
	// Decode storage slices
	storage_slices_len := e.get_int()!
	o.storageslices = []StorageSlice{len: storage_slices_len}
	for i in 0 .. storage_slices_len {
		o.storageslices[i].id = e.get_int()!
		o.storageslices[i].price_cc = e.get_f64()!
		o.storageslices[i].pricing_policy.name = e.get_string()!
		o.storageslices[i].pricing_policy.details = e.get_string()!
		o.storageslices[i].pricing_policy.marketplace_year_discounts = e.get_list_int()!
		o.storageslices[i].sla_policy.uptime = e.get_f32()!
		o.storageslices[i].sla_policy.max_response_time_ms = e.get_u32()!
		o.storageslices[i].sla_policy.sla_bandwidth_mbit = e.get_int()!
		o.storageslices[i].sla_policy.sla_penalty = e.get_int()!
	}
	
	// Decode devices
	o.devices.vendor = e.get_string()!
	
	storage_devices_len := e.get_int()!
	o.devices.storage = []StorageDevice{len: storage_devices_len}
	for i in 0 .. storage_devices_len {
		o.devices.storage[i].id = e.get_string()!
		o.devices.storage[i].size_gb = e.get_f64()!
		o.devices.storage[i].description = e.get_string()!
	}
	
	memory_devices_len := e.get_int()!
	o.devices.memory = []MemoryDevice{len: memory_devices_len}
	for i in 0 .. memory_devices_len {
		o.devices.memory[i].id = e.get_string()!
		o.devices.memory[i].size_gb = e.get_f64()!
		o.devices.memory[i].description = e.get_string()!
	}
	
	cpu_devices_len := e.get_int()!
	o.devices.cpu = []CPUDevice{len: cpu_devices_len}
	for i in 0 .. cpu_devices_len {
		o.devices.cpu[i].id = e.get_string()!
		o.devices.cpu[i].cores = e.get_int()!
		o.devices.cpu[i].passmark = e.get_int()!
		o.devices.cpu[i].description = e.get_string()!
		o.devices.cpu[i].cpu_brand = e.get_string()!
		o.devices.cpu[i].cpu_version = e.get_string()!
	}
	
	gpu_devices_len := e.get_int()!
	o.devices.gpu = []GPUDevice{len: gpu_devices_len}
	for i in 0 .. gpu_devices_len {
		o.devices.gpu[i].id = e.get_string()!
		o.devices.gpu[i].cores = e.get_int()!
		o.devices.gpu[i].memory_gb = e.get_f64()!
		o.devices.gpu[i].description = e.get_string()!
		o.devices.gpu[i].gpu_brand = e.get_string()!
		o.devices.gpu[i].gpu_version = e.get_string()!
	}
	
	network_devices_len := e.get_int()!
	o.devices.network = []NetworkDevice{len: network_devices_len}
	for i in 0 .. network_devices_len {
		o.devices.network[i].id = e.get_string()!
		o.devices.network[i].speed_mbps = e.get_int()!
		o.devices.network[i].description = e.get_string()!
	}
	
	o.country = e.get_string()!
	o.capacity.storage_gb = e.get_f64()!
	o.capacity.mem_gb = e.get_f64()!
	o.capacity.mem_gb_gpu = e.get_f64()!
	o.capacity.passmark = e.get_int()!
	o.capacity.vcores = e.get_int()!
	o.birthtime = e.get_u32()!
	o.pubkey = e.get_string()!
	o.signature_node = e.get_string()!
	o.signature_farmer = e.get_string()!
}

@[params]
pub struct NodeArg {
pub mut:
	name             string
	description      string
	nodegroupid      int
	uptime           int
	computeslices    []ComputeSlice
	storageslices    []StorageSlice
	devices          DeviceInfo
	country          string
	capacity         NodeCapacity
	birthtime        u32
	pubkey           string
	signature_node   string
	signature_farmer string
}

pub fn (mut self DBNode) new(args NodeArg) !Node {
	mut o := Node{
		nodegroupid:     args.nodegroupid
		uptime:          args.uptime
		computeslices:   args.computeslices
		storageslices:   args.storageslices
		devices:         args.devices
		country:         args.country
		capacity:        args.capacity
		birthtime:       args.birthtime
		pubkey:          args.pubkey
		signature_node:  args.signature_node
		signature_farmer: args.signature_farmer
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBNode) set(o Node) !Node {
	return self.db.set[Node](o)!
}

pub fn (mut self DBNode) delete(id u32) ! {
	self.db.delete[Node](id)!
}

pub fn (mut self DBNode) exist(id u32) !bool {
	return self.db.exists[Node](id)!
}

pub fn (mut self DBNode) get(id u32) !Node {
	mut o, data := self.db.get_data[Node](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBNode) list() ![]Node {
	return self.db.list[Node]()!.map(self.get(it)!)
}