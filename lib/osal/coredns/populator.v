module coredns

import incubaid.herolib.core.redisclient
import x.json2

// new_dns_record_set creates a new DNSRecordSet
pub fn new_dns_record_set() DNSRecordSet {
	return DNSRecordSet{}
}

pub struct AddSRVRecordArgs {
	SRV_Record
pub:
	service  string @[required]
	protocol string @[required]
	host     string @[required]
}

// add_srv adds an SRV record to the set
pub fn (mut rs DNSRecordSet) add_srv(args AddSRVRecordArgs) {
	key := '_${args.service}._${args.protocol}.${args.host}'
	mut rec := rs.records[key] or { Record{} }
	if mut v := rec.srv {
		v << args.SRV_Record
	} else {
		rec.srv = [args.SRV_Record]
	}

	rs.records[key] = rec
}

pub struct AddTXTRecordArgs {
	TXT_Record
pub:
	sub_domain string = '@'
}

// add_txt adds a TXT record to the set
pub fn (mut rs DNSRecordSet) add_txt(args AddTXTRecordArgs) {
	mut rec := rs.records[args.sub_domain] or { Record{} }
	if mut v := rec.txt {
		v << args.TXT_Record
	} else {
		rec.txt = [args.TXT_Record]
	}

	rs.records[args.sub_domain] = rec
}

pub struct AddMXRecordArgs {
	MX_Record
pub:
	sub_domain string = '@'
}

// add_mx adds an MX record to the set
pub fn (mut rs DNSRecordSet) add_mx(args AddMXRecordArgs) {
	mut rec := rs.records[args.sub_domain] or { Record{} }
	if mut v := rec.mx {
		v << args.MX_Record
	} else {
		rec.mx = [args.MX_Record]
	}

	rs.records[args.sub_domain] = rec
}

pub struct AddARecordArgs {
	A_Record
pub:
	sub_domain string = '@'
}

// add_a adds an A record to the set
pub fn (mut rs DNSRecordSet) add_a(args AddARecordArgs) {
	mut rec := rs.records[args.sub_domain] or { Record{} }
	if mut v := rec.a {
		v << args.A_Record
	} else {
		rec.a = [args.A_Record]
	}

	rs.records[args.sub_domain] = rec
}

pub struct AddAAAARecordArgs {
	AAAA_Record
pub:
	sub_domain string = '@'
}

// add_aaaa adds an AAAA record to the set
pub fn (mut rs DNSRecordSet) add_aaaa(args AddAAAARecordArgs) {
	mut rec := rs.records[args.sub_domain] or { Record{} }
	if mut v := rec.aaaa {
		v << args.AAAA_Record
	} else {
		rec.aaaa = [args.AAAA_Record]
	}

	rs.records[args.sub_domain] = rec
}

pub struct AddNSRecordArgs {
	NS_Record
pub:
	sub_domain string = '@'
}

// add_ns adds an NS record to the set
pub fn (mut rs DNSRecordSet) add_ns(args AddNSRecordArgs) {
	mut rec := rs.records[args.sub_domain] or { Record{} }
	if mut v := rec.ns {
		v << args.NS_Record
	} else {
		rec.ns = [args.NS_Record]
	}

	rs.records[args.sub_domain] = rec
}

// set_soa sets the SOA record for the set
pub fn (mut rs DNSRecordSet) set_soa(args SOA_Record) {
	mut rec := rs.records['@'] or { Record{} }
	rec.soa = args
	rs.records['@'] = rec
}

pub struct SetArgs {
pub:
	domain     string
	key_prefix string
}

// populate_redis populates Redis with the DNS records
// domain e.g. example.com.  (not sure the . is at end)
pub fn (mut rs DNSRecordSet) set(args SetArgs) ! {
	mut redis := rs.redis or {
		r := redisclient.core_get()!
		rs.redis = r
		r
	}

	key := '${args.key_prefix}${args.domain}.'
	for field, val in rs.records {
		redis.hset(key, field, json2.encode(val))!
	}
}

pub fn (mut rs DNSRecordSet) example() ! {
	// Create and populate DNS records
	rs.set_soa(mbox: 'hostmaster.example.net.', ns: 'ns1.example.net.')
	rs.add_srv(service: 'ssh', protocol: 'tcp', host: 'host1', target: 'tcp.example.com.', port: 123)
	rs.add_txt(sub_domain: '*', text: 'this is a wildcard')
	rs.add_mx(sub_domain: '*', host: 'host1.example.net.')
	rs.add_a(sub_domain: 'host1', ip: '5.5.5.5')
	rs.add_aaaa(sub_domain: 'host1', ip: '2001:db8::1')
	rs.add_txt(sub_domain: 'sub.*', text: 'this is not a wildcard')
	rs.add_ns(sub_domain: 'subdel', host: 'ns1.subdel.example.net.')
	rs.add_ns(sub_domain: 'subdel', host: 'ns2.subdel.example.net.')
	rs.add_ns(host: 'ns1.example.net.')
	rs.add_ns(host: 'ns2.example.net.')

	// Store records in Redis
	rs.set(domain: 'example.com')!
}
