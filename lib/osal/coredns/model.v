module coredns

import incubaid.herolib.core.redisclient

// // Input parameter structs for each record type

// DNSRecordSet represents a set of DNS records
struct DNSRecordSet {
pub mut:
	redis   ?&redisclient.Redis
	records map[string]Record
}

pub struct Record {
pub mut:
	a     ?[]A_Record
	aaaa  ?[]AAAA_Record
	txt   ?[]TXT_Record
	cname ?[]CNAME_Record
	ns    ?[]NS_Record
	mx    ?[]MX_Record
	srv   ?[]SRV_Record
	caa   ?[]CAA_Record
	soa   ?SOA_Record
}

@[params]
pub struct A_Record {
pub:
	ip  string @[required]
	ttl int = 300
}

@[params]
pub struct AAAA_Record {
pub:
	ip  string @[required]
	ttl int = 300
}

@[params]
pub struct TXT_Record {
pub:
	text string @[required]
	ttl  int = 300
}

@[params]
pub struct CNAME_Record {
pub:
	host string
	ttl  int = 300
}

@[params]
pub struct NS_Record {
pub:
	host string @[required]
	ttl  int = 300
}

@[params]
pub struct MX_Record {
pub:
	host       string @[required]
	preference int = 10
	ttl        int = 300
}

@[params]
pub struct SRV_Record {
pub:
	target   string @[required]
	port     int    @[required]
	priority int = 10
	weight   int = 100
	ttl      int = 300
}

@[params]
pub struct CAA_Record {
pub:
	flag  u8
	tag   string
	value string
}

@[params]
pub struct SOA_Record {
pub:
	mbox    string @[required]
	ns      string @[required]
	refresh int = 44
	retry   int = 55
	expire  int = 66
	minttl  int = 100
	ttl     int = 300
}
