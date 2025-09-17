// lib/threefold/models_ledger/dnszone.v
module models_ledger

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// NameType defines the supported DNS record types
pub enum NameType {
	a
	aaaa
	cname
	mx
	txt
	srv
	ptr
	ns
}

// NameCat defines the category of the DNS record
pub enum NameCat {
	ipv4
	ipv6
	mycelium
}

// DNSZoneStatus defines the status of a DNS zone
pub enum DNSZoneStatus {
	active
	suspended
	archived
}

// DNSRecord represents a DNS record configuration
pub struct DNSRecord {
pub mut:
	subdomain   string
	record_type NameType
	value       string
	priority    u32
	ttl         u32
	is_active   bool
	cat         NameCat
	is_wildcard bool
}

// SOARecord represents SOA (Start of Authority) record for a DNS zone
pub struct SOARecord {
pub mut:
	zone_id     u32
	primary_ns  string
	admin_email string
	serial      u64
	refresh     u32
	retry       u32
	expire      u32
	minimum_ttl u32
	is_active   bool
}

// DNSZone represents a DNS zone with its configuration and records
@[heap]
pub struct DNSZone {
	db.Base
pub mut:
	domain         string @[index]
	dnsrecords     []DNSRecord
	administrators []u32
	status         DNSZoneStatus
	metadata       map[string]string
	soarecord      []SOARecord
}

pub struct DBDNSZone {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self DNSZone) type_name() string {
	return 'dnszone'
}

pub fn (self DNSZone) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a DNS zone. Returns the ID of the DNS zone.'
		}
		'get' {
			return 'Retrieve a DNS zone by ID. Returns the DNS zone object.'
		}
		'delete' {
			return 'Delete a DNS zone by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a DNS zone exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all DNS zones. Returns an array of DNS zone objects.'
		}
		else {
			return 'DNS zone management operations'
		}
	}
}

pub fn (self DNSZone) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"dnszone": {"domain": "example.com", "status": "active"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"domain": "example.com", "status": "active"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"domain": "example.com", "status": "active"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self DNSZone) dump(mut e encoder.Encoder) ! {
	e.add_string(self.domain)
	
	// dnsrecords
	e.add_int(self.dnsrecords.len)
	for record in self.dnsrecords {
		e.add_string(record.subdomain)
		e.add_int(int(record.record_type))
		e.add_string(record.value)
		e.add_u32(record.priority)
		e.add_u32(record.ttl)
		e.add_bool(record.is_active)
		e.add_int(int(record.cat))
		e.add_bool(record.is_wildcard)
	}
	
	e.add_list_u32(self.administrators)
	e.add_int(int(self.status))
	
	// metadata map
	e.add_int(self.metadata.len)
	for key, value in self.metadata {
		e.add_string(key)
		e.add_string(value)
	}
	
	// soarecords
	e.add_int(self.soarecord.len)
	for soa in self.soarecord {
		e.add_u32(soa.zone_id)
		e.add_string(soa.primary_ns)
		e.add_string(soa.admin_email)
		e.add_u64(soa.serial)
		e.add_u32(soa.refresh)
		e.add_u32(soa.retry)
		e.add_u32(soa.expire)
		e.add_u32(soa.minimum_ttl)
		e.add_bool(soa.is_active)
	}
}

fn (mut self DBDNSZone) load(mut o DNSZone, mut e encoder.Decoder) ! {
	o.domain = e.get_string()!
	
	// dnsrecords
	records_len := e.get_int()!
	o.dnsrecords = []DNSRecord{cap: records_len}
	for _ in 0 .. records_len {
		record := DNSRecord{
			subdomain:   e.get_string()!
			record_type: NameType(e.get_int()!)
			value:       e.get_string()!
			priority:    e.get_u32()!
			ttl:         e.get_u32()!
			is_active:   e.get_bool()!
			cat:         NameCat(e.get_int()!)
			is_wildcard: e.get_bool()!
		}
		o.dnsrecords << record
	}
	
	o.administrators = e.get_list_u32()!
	o.status = DNSZoneStatus(e.get_int()!)
	
	// metadata map
	metadata_len := e.get_int()!
	o.metadata = map[string]string{}
	for _ in 0 .. metadata_len {
		key := e.get_string()!
		value := e.get_string()!
		o.metadata[key] = value
	}
	
	// soarecords
	soa_len := e.get_int()!
	o.soarecord = []SOARecord{cap: soa_len}
	for _ in 0 .. soa_len {
		soa := SOARecord{
			zone_id:     e.get_u32()!
			primary_ns:  e.get_string()!
			admin_email: e.get_string()!
			serial:      e.get_u64()!
			refresh:     e.get_u32()!
			retry:       e.get_u32()!
			expire:      e.get_u32()!
			minimum_ttl: e.get_u32()!
			is_active:   e.get_bool()!
		}
		o.soarecord << soa
	}
}

@[params]
pub struct DNSZoneArg {
pub mut:
	name           string
	description    string
	domain         string
	dnsrecords     []DNSRecord
	administrators []u32
	status         DNSZoneStatus
	metadata       map[string]string
	soarecord      []SOARecord
}

pub fn (mut self DBDNSZone) new(args DNSZoneArg) !DNSZone {
	mut o := DNSZone{
		domain:         args.domain
		dnsrecords:     args.dnsrecords
		administrators: args.administrators
		status:         args.status
		metadata:       args.metadata
		soarecord:      args.soarecord
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBDNSZone) set(o DNSZone) !DNSZone {
	return self.db.set[DNSZone](o)!
}

pub fn (mut self DBDNSZone) delete(id u32) ! {
	self.db.delete[DNSZone](id)!
}

pub fn (mut self DBDNSZone) exist(id u32) !bool {
	return self.db.exists[DNSZone](id)!
}

pub fn (mut self DBDNSZone) get(id u32) !DNSZone {
	mut o, data := self.db.get_data[DNSZone](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBDNSZone) list() ![]DNSZone {
	return self.db.list[DNSZone]()!.map(self.get(it)!)
}