#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_dnszone_new() {
	mut mydb := setup_test_db()!
	mut dns_db := DBDNSZone{db: &mydb}

	// Create test DNS zone with records and SOA
	dns_record1 := DNSRecord{
		subdomain: 'www'
		record_type: .a
		value: '192.168.1.1'
		priority: 0
		ttl: 3600
		is_active: true
		cat: .ipv4
		is_wildcard: false
	}

	dns_record2 := DNSRecord{
		subdomain: 'mail'
		record_type: .mx
		value: 'mail.example.com'
		priority: 10
		ttl: 3600
		is_active: true
		cat: .ipv4
		is_wildcard: false
	}

	soa_record := SOARecord{
		zone_id: 1
		primary_ns: 'ns1.example.com'
		admin_email: 'admin@example.com'
		serial: 2023120101
		refresh: 3600
		retry: 1800
		expire: 604800
		minimum_ttl: 86400
		is_active: true
	}

	mut dnszone := dns_db.new(
		name: 'Test DNS Zone'
		description: 'A test DNS zone for unit testing'
		domain: 'example.com'
		dnsrecords: [dns_record1, dns_record2]
		administrators: [u32(1), 2, 3]
		status: .active
		min_signatures: 2
		metadata: {'zone_type': 'primary', 'provider': 'test'}
		soarecord: [soa_record]
	)!

	// Verify the DNS zone was created with correct values
	assert dnszone.name == 'Test DNS Zone'
	assert dnszone.description == 'A test DNS zone for unit testing'
	assert dnszone.domain == 'example.com'
	assert dnszone.dnsrecords.len == 2
	assert dnszone.dnsrecords[0].subdomain == 'www'
	assert dnszone.dnsrecords[1].record_type == .mx
	assert dnszone.administrators.len == 3
	assert dnszone.status == .active
	assert dnszone.min_signatures == 2
	assert dnszone.metadata.len == 2
	assert dnszone.soarecord.len == 1
	assert dnszone.soarecord[0].primary_ns == 'ns1.example.com'
	assert dnszone.id == 0 // Should be 0 before saving
	assert dnszone.updated_at > 0 // Should have timestamp
}

fn test_dnszone_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut dns_db := DBDNSZone{db: &mydb}

	// Create a complex DNS zone with multiple record types
	records := [
		DNSRecord{
			subdomain: '@'
			record_type: .a
			value: '203.0.113.1'
			priority: 0
			ttl: 300
			is_active: true
			cat: .ipv4
			is_wildcard: false
		},
		DNSRecord{
			subdomain: 'www'
			record_type: .cname
			value: 'example.com'
			priority: 0
			ttl: 3600
			is_active: true
			cat: .ipv4
			is_wildcard: false
		},
		DNSRecord{
			subdomain: '*'
			record_type: .a
			value: '203.0.113.2'
			priority: 0
			ttl: 3600
			is_active: false
			cat: .ipv4
			is_wildcard: true
		},
		DNSRecord{
			subdomain: 'ipv6'
			record_type: .aaaa
			value: '2001:db8::1'
			priority: 0
			ttl: 3600
			is_active: true
			cat: .ipv6
			is_wildcard: false
		}
	]

	soa_records := [
		SOARecord{
			zone_id: 1
			primary_ns: 'ns1.test.com'
			admin_email: 'dns-admin@test.com'
			serial: 2023120201
			refresh: 7200
			retry: 3600
			expire: 1209600
			minimum_ttl: 300
			is_active: true
		},
		SOARecord{
			zone_id: 2
			primary_ns: 'ns2.test.com'
			admin_email: 'backup-admin@test.com'
			serial: 2023120202
			refresh: 7200
			retry: 3600
			expire: 1209600
			minimum_ttl: 300
			is_active: false
		}
	]

	mut original_zone := dns_db.new(
		name: 'Encoding Test Zone'
		description: 'Testing encoding and decoding functionality'
		domain: 'test.com'
		dnsrecords: records
		administrators: [u32(10), 20, 30]
		status: .suspended
		min_signatures: 3
		metadata: {
			'zone_type': 'secondary'
			'provider': 'test_provider'
			'environment': 'staging'
			'auto_dnssec': 'true'
		}
		soarecord: soa_records
	)!

	// Test encoding
	mut encoder_obj := encoder.encoder_new()
	original_zone.dump(mut encoder_obj)!
	encoded_data := encoder_obj.data

	// Test decoding
	mut decoder_obj := encoder.decoder_new(encoded_data)
	mut decoded_zone := DNSZone{}
	dns_db.load(mut decoded_zone, mut decoder_obj)!

	// Verify all fields match after encoding/decoding
	assert decoded_zone.domain == original_zone.domain
	assert decoded_zone.status == original_zone.status
	assert decoded_zone.min_signatures == original_zone.min_signatures

	// Verify administrators
	assert decoded_zone.administrators.len == original_zone.administrators.len
	for i, admin in original_zone.administrators {
		assert decoded_zone.administrators[i] == admin
	}

	// Verify metadata map
	assert decoded_zone.metadata.len == original_zone.metadata.len
	for key, value in original_zone.metadata {
		assert decoded_zone.metadata[key] == value
	}

	// Verify DNS records
	assert decoded_zone.dnsrecords.len == original_zone.dnsrecords.len
	for i, record in original_zone.dnsrecords {
		decoded_record := decoded_zone.dnsrecords[i]
		assert decoded_record.subdomain == record.subdomain
		assert decoded_record.record_type == record.record_type
		assert decoded_record.value == record.value
		assert decoded_record.priority == record.priority
		assert decoded_record.ttl == record.ttl
		assert decoded_record.is_active == record.is_active
		assert decoded_record.cat == record.cat
		assert decoded_record.is_wildcard == record.is_wildcard
	}

	// Verify SOA records
	assert decoded_zone.soarecord.len == original_zone.soarecord.len
	for i, soa in original_zone.soarecord {
		decoded_soa := decoded_zone.soarecord[i]
		assert decoded_soa.zone_id == soa.zone_id
		assert decoded_soa.primary_ns == soa.primary_ns
		assert decoded_soa.admin_email == soa.admin_email
		assert decoded_soa.serial == soa.serial
		assert decoded_soa.refresh == soa.refresh
		assert decoded_soa.retry == soa.retry
		assert decoded_soa.expire == soa.expire
		assert decoded_soa.minimum_ttl == soa.minimum_ttl
		assert decoded_soa.is_active == soa.is_active
	}
}

fn test_dnszone_set_and_get() {
	mut mydb := setup_test_db()!
	mut dns_db := DBDNSZone{db: &mydb}

	// Create simple DNS zone
	record := DNSRecord{
		subdomain: 'api'
		record_type: .a
		value: '192.168.1.100'
		priority: 0
		ttl: 3600
		is_active: true
		cat: .ipv4
		is_wildcard: false
	}

	mut dnszone := dns_db.new(
		name: 'DB Test Zone'
		description: 'Testing database operations'
		domain: 'dbtest.com'
		dnsrecords: [record]
		administrators: [u32(5)]
		status: .active
		min_signatures: 1
		metadata: {'test': 'true'}
		soarecord: []SOARecord{}
	)!

	// Save the DNS zone
	dnszone = dns_db.set(dnszone)!

	// Verify ID was assigned
	assert dnszone.id > 0
	original_id := dnszone.id

	// Retrieve the DNS zone
	retrieved_zone := dns_db.get(dnszone.id)!

	// Verify all fields match through the database roundtrip
	assert retrieved_zone.id == original_id
	assert retrieved_zone.name == 'DB Test Zone'
	assert retrieved_zone.description == 'Testing database operations'
	assert retrieved_zone.domain == 'dbtest.com'
	assert retrieved_zone.status == .active
	assert retrieved_zone.min_signatures == 1
	assert retrieved_zone.administrators.len == 1
	assert retrieved_zone.administrators[0] == 5
	assert retrieved_zone.metadata.len == 1
	assert retrieved_zone.metadata['test'] == 'true'
	assert retrieved_zone.dnsrecords.len == 1
	assert retrieved_zone.dnsrecords[0].subdomain == 'api'
	assert retrieved_zone.dnsrecords[0].value == '192.168.1.100'
}

fn test_dnszone_update() {
	mut mydb := setup_test_db()!
	mut dns_db := DBDNSZone{db: &mydb}

	// Create and save a DNS zone
	mut dnszone := dns_db.new(
		name: 'Original Zone'
		description: 'Original description'
		domain: 'original.com'
		dnsrecords: []DNSRecord{}
		administrators: [u32(1)]
		status: .active
		min_signatures: 1
		metadata: {'version': '1.0'}
		soarecord: []SOARecord{}
	)!

	dnszone = dns_db.set(dnszone)!
	original_id := dnszone.id
	original_created_at := dnszone.created_at

	// Update the DNS zone
	new_record := DNSRecord{
		subdomain: 'updated'
		record_type: .a
		value: '10.0.0.1'
		priority: 0
		ttl: 300
		is_active: true
		cat: .ipv4
		is_wildcard: false
	}

	dnszone.name = 'Updated Zone'
	dnszone.description = 'Updated description'
	dnszone.domain = 'updated.com'
	dnszone.dnsrecords = [new_record]
	dnszone.status = .suspended
	dnszone.metadata = {'version': '2.0', 'updated': 'true'}
	dnszone.min_signatures = 2

	dnszone = dns_db.set(dnszone)!

	// Verify ID remains the same
	assert dnszone.id == original_id
	assert dnszone.created_at == original_created_at

	// Retrieve and verify updates
	updated_zone := dns_db.get(dnszone.id)!
	assert updated_zone.name == 'Updated Zone'
	assert updated_zone.description == 'Updated description'
	assert updated_zone.domain == 'updated.com'
	assert updated_zone.status == .suspended
	assert updated_zone.min_signatures == 2
	assert updated_zone.metadata.len == 2
	assert updated_zone.metadata['version'] == '2.0'
	assert updated_zone.dnsrecords.len == 1
	assert updated_zone.dnsrecords[0].subdomain == 'updated'
}

fn test_dnszone_exist_and_delete() {
	mut mydb := setup_test_db()!
	mut dns_db := DBDNSZone{db: &mydb}

	// Test non-existent DNS zone
	exists := dns_db.exist(999)!
	assert exists == false

	// Create and save a DNS zone
	mut dnszone := dns_db.new(
		name: 'To Be Deleted'
		description: 'This DNS zone will be deleted'
		domain: 'delete.com'
		dnsrecords: []DNSRecord{}
		administrators: []u32{}
		status: .archived
		min_signatures: 0
		metadata: map[string]string{}
		soarecord: []SOARecord{}
	)!

	dnszone = dns_db.set(dnszone)!
	zone_id := dnszone.id

	// Test existing DNS zone
	exists_after_save := dns_db.exist(zone_id)!
	assert exists_after_save == true

	// Delete the DNS zone
	dns_db.delete(zone_id)!

	// Verify it no longer exists
	exists_after_delete := dns_db.exist(zone_id)!
	assert exists_after_delete == false

	// Verify get fails
	if _ := dns_db.get(zone_id) {
		panic('Should not be able to get deleted DNS zone')
	}
}

fn test_dnszone_list() {
	mut mydb := setup_test_db()!
	mut dns_db := DBDNSZone{db: &mydb}

	// Initially should be empty
	initial_list := dns_db.list()!
	initial_count := initial_list.len

	// Create multiple DNS zones
	mut zone1 := dns_db.new(
		name: 'Zone 1'
		description: 'First zone'
		domain: 'zone1.com'
		dnsrecords: []DNSRecord{}
		administrators: [u32(1)]
		status: .active
		min_signatures: 1
		metadata: {'type': 'primary'}
		soarecord: []SOARecord{}
	)!

	mut zone2 := dns_db.new(
		name: 'Zone 2'
		description: 'Second zone'
		domain: 'zone2.net'
		dnsrecords: []DNSRecord{}
		administrators: [u32(1), 2]
		status: .suspended
		min_signatures: 2
		metadata: {'type': 'secondary'}
		soarecord: []SOARecord{}
	)!

	// Save both zones
	zone1 = dns_db.set(zone1)!
	zone2 = dns_db.set(zone2)!

	// List zones
	zone_list := dns_db.list()!

	// Should have 2 more zones than initially
	assert zone_list.len == initial_count + 2

	// Find our zones in the list
	mut found_zone1 := false
	mut found_zone2 := false

	for zone in zone_list {
		if zone.domain == 'zone1.com' {
			found_zone1 = true
			assert zone.status == .active
			assert zone.metadata['type'] == 'primary'
		}
		if zone.domain == 'zone2.net' {
			found_zone2 = true
			assert zone.status == .suspended
			assert zone.administrators.len == 2
		}
	}

	assert found_zone1 == true
	assert found_zone2 == true
}

fn test_dnszone_record_types() {
	mut mydb := setup_test_db()!
	mut dns_db := DBDNSZone{db: &mydb}

	// Test all DNS record types
	record_types := [NameType.a, .aaaa, .cname, .mx, .txt, .srv, .ptr, .ns]
	record_cats := [NameCat.ipv4, .ipv6, .mycelium]

	mut records := []DNSRecord{}
	for i, rtype in record_types {
		cat := record_cats[i % record_cats.len]
		records << DNSRecord{
			subdomain: 'test${i}'
			record_type: rtype
			value: 'value${i}'
			priority: u32(i)
			ttl: u32(300 + i * 100)
			is_active: i % 2 == 0
			cat: cat
			is_wildcard: i > 4
		}
	}

	mut zone := dns_db.new(
		name: 'Record Types Test'
		description: 'Testing all record types'
		domain: 'recordtest.com'
		dnsrecords: records
		administrators: []u32{}
		status: .active
		min_signatures: 0
		metadata: map[string]string{}
		soarecord: []SOARecord{}
	)!

	zone = dns_db.set(zone)!
	retrieved_zone := dns_db.get(zone.id)!

	assert retrieved_zone.dnsrecords.len == record_types.len
	for i, record in retrieved_zone.dnsrecords {
		assert record.record_type == record_types[i]
		assert record.cat == record_cats[i % record_cats.len]
		assert record.subdomain == 'test${i}'
		assert record.is_active == (i % 2 == 0)
		assert record.is_wildcard == (i > 4)
	}
}