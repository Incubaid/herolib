module coredns

import incubaid.herolib.core.playbook

// play_dns processes DNS-related actions from heroscript
pub fn play_dns(mut plbook playbook.PlayBook) !DNSRecordSet {
	mut recordset := new_dns_record_set()

	// Find all actions starting with dns.
	dns_actions := plbook.find(filter: 'dns.')!

	for action in dns_actions {
		mut p := action.params

		match action.name {
			'a_record' {
				recordset.add_a(
					sub_domain: p.get_default('sub_domain', '@')!
					ip:         p.get('ip')!
					ttl:        p.get_int_default('ttl', 300)!
				)
			}
			'aaaa_record' {
				recordset.add_aaaa(
					sub_domain: p.get_default('sub_domain', '@')!
					ip:         p.get('ip')!
					ttl:        p.get_int_default('ttl', 300)!
				)
			}
			'mx_record' {
				recordset.add_mx(
					sub_domain: p.get_default('sub_domain', '@')!
					host:       p.get('host')!
					preference: p.get_int_default('preference', 10)!
					ttl:        p.get_int_default('ttl', 300)!
				)
			}
			'txt_record' {
				recordset.add_txt(
					sub_domain: p.get_default('sub_domain', '@')!
					text:       p.get('text')!
					ttl:        p.get_int_default('ttl', 300)!
				)
			}
			'srv_record' {
				recordset.add_srv(
					host:     p.get('host')!
					protocol: p.get('protocol')!
					service:  p.get('service')!
					target:   p.get('target')!
					port:     p.get_int('port')!
					priority: p.get_int_default('priority', 10)!
					weight:   p.get_int_default('weight', 100)!
					ttl:      p.get_int_default('ttl', 300)!
				)
			}
			'ns_record' {
				recordset.add_ns(
					sub_domain: p.get_default('sub_domain', '@')!
					host:       p.get('host')!
					ttl:        p.get_int_default('ttl', 300)!
				)
			}
			'soa_record' {
				recordset.set_soa(
					mbox:    p.get('mbox')!
					ns:      p.get('ns')!
					refresh: p.get_int_default('refresh', 44)!
					retry:   p.get_int_default('retry', 55)!
					expire:  p.get_int_default('expire', 66)!
					minttl:  p.get_int_default('minttl', 100)!
					ttl:     p.get_int_default('ttl', 300)!
				)
			}
			else {
				// Unknown action, skip
				continue
			}
		}
	}

	return recordset
}

// Example usage:
/*
!!dns.a_record
    sub_domain: 'host1'
    ip: '1.2.3.4'
    ttl: 300

!!dns.aaaa_record
    sub_domain: 'host1'
    ip: '2001:db8::1'
    ttl: 300

!!dns.mx_record
	sub_domain: '*'
    host: 'mail.example.com'
    preference: 10
    ttl: 300

!!dns.txt_record
	sub_domain: '*'
    text: 'v=spf1 mx ~all'
    ttl: 300

!!dns.srv_record
	service: 'ssh'
	protocol: 'tcp'
	host: 'host1'
    target: 'sip.example.com'
    port: 5060
    priority: 10
    weight: 100
    ttl: 300

!!dns.ns_record
    host: 'ns1.example.com'
    ttl: 300

!!dns.soa_record
    mbox: 'hostmaster.example.com'
    ns: 'ns1.example.com'
    refresh: 44
    retry: 55
    expire: 66
    minttl: 100
    ttl: 300
*/
