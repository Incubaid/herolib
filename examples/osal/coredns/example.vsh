#!/usr/bin/env -S v -n -w -cg -d use_openssl -enable-globals run

import incubaid.herolib.installers.infra.coredns as coredns_installer
import incubaid.herolib.osal.coredns
import incubaid.herolib.core.playbook

// coredns_installer.delete()!
mut installer := coredns_installer.get()!
// coredns_installer.fix()!
installer.start()!

mut script := "
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
"

mut plbook := playbook.new(text: script)!
mut set := coredns.play_dns(mut plbook)!
set.set(key_prefix: 'dns:', domain: 'heroexample.com')!
