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

// DNSRecord represents a DNS record configuration.
pub struct DNSRecord {
pub mut:
	subdomain   string   @[required] // The subdomain for the record (e.g., 'www', '@' for the root).
	record_type NameType @[required] // The type of the DNS record (e.g., A, AAAA, CNAME).
	value       string   @[required] // The value of the DNS record (e.g., an IP address, a hostname).
	priority    u32     // The priority of the record, used for MX records.
	ttl         u32     // The Time To Live for the record in seconds.
	is_active   bool    // Indicates if the record is currently active.
	cat         NameCat // The category of the DNS record, for internal classification.
	is_wildcard bool    // Indicates if this is a wildcard record (e.g., '*.example.com').
}

// SOARecord represents the Start of Authority (SOA) record for a DNS zone.
pub struct SOARecord {
pub mut:
	zone_id     u32 // The ID of the zone this SOA record belongs to.
	primary_ns  string @[required] // The primary name server for the zone.
	admin_email string @[required] // The email address of the zone administrator.
	serial      u64    @[required] // The serial number of the zone, incremented on changes.
	refresh     u32  // The time in seconds before the zone should be refreshed.
	retry       u32  // The time in seconds before a failed refresh should be retried.
	expire      u32  // The time in seconds before a secondary server should stop answering for the zone.
	minimum_ttl u32  // The minimum TTL for records in the zone.
	is_active   bool // Indicates if the SOA record is currently active.
}

// DNSZone represents a domain name and its associated DNS records.
@[heap]
pub struct DNSZone {
	db.Base
pub mut:
	domain         string @[index; required] // The domain name of the zone (e.g., 'example.com').
	dnsrecords     []DNSRecord       // A list of DNS records associated with this zone.
	administrators []u32             // A list of user IDs that are administrators for this zone.
	min_signatures u32               // The minimum number of signatures required for administrative actions.
	status         DNSZoneStatus     // The current status of the DNS zone (e.g., active, suspended).
	metadata       map[string]string // A map for storing arbitrary metadata as key-value pairs.
	soarecord      []SOARecord       // The Start of Authority (SOA) record for this zone.
}

pub struct DBDNSZone {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self DNSZone) type_name() string {
	return 'dnszone'
}

pub fn (self DNSZone) description(methodname string) string {
	return match methodname {
		'set' { 'Create or update a DNS zone. Returns the ID of the DNS zone.' }
		'get' { 'Retrieve a DNS zone by its unique ID.' }
		'delete' { 'Deletes a DNS zone by its unique ID.' }
		'exist' { 'Checks if a DNS zone with the given ID exists.' }
		'find' { 'Finds DNS zones based on a filter expression.' }
		'count' { 'Counts the number of DNS zones that match a filter expression.' }
		'list' { 'Lists all DNS zones, optionally filtered and sorted.' }
		else { 'A DNS zone represents a domain name and its associated records.' }
	}
}

pub fn (self DNSZone) example(methodname string) (string, string) {
	return match methodname {
		'set' { '{"dnszone": {"id": 1, "domain": "example.com", "status": "active"}}', '1' }
		'get' { '{"id": 1}', '{"id": 1, "domain": "example.com", "status": "active"}' }
		'delete' { '{"id": 1}', 'true' }
		'exist' { '{"id": 1}', 'true' }
		'find' { '{"filter": "domain=\'example.com\'"}', '[{"id": 1, "domain": "example.com", "status": "active"}]' }
		'count' { '{"filter": "domain=\'example.com\'"}', '1' }
		'list' { '{}', '[{"id": 1, "domain": "example.com", "status": "active"}]' }
		else { '{}', '{}' }
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
	e.add_u32(self.min_signatures)

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
			record_type: unsafe { NameType(e.get_int()!) }
			value:       e.get_string()!
			priority:    e.get_u32()!
			ttl:         e.get_u32()!
			is_active:   e.get_bool()!
			cat:         unsafe { NameCat(e.get_int()!) }
			is_wildcard: e.get_bool()!
		}
		o.dnsrecords << record
	}

	o.administrators = e.get_list_u32()!
	o.status = unsafe { DNSZoneStatus(e.get_int()!) }
	o.min_signatures = e.get_u32()!

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
	min_signatures u32
	metadata       map[string]string
	soarecord      []SOARecord
}

pub fn (mut self DBDNSZone) new(args DNSZoneArg) !DNSZone {
	mut o := DNSZone{
		domain:         args.domain
		dnsrecords:     args.dnsrecords
		administrators: args.administrators
		status:         args.status
		min_signatures: args.min_signatures
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
