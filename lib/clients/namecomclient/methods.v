// File: lib/clients/namecomclient/methods.v
module namecomclient

import incubaid.herolib.core.httpconnection
import json

//
// Hello / Test Connection
//

// hello tests the API connection and returns server info
pub fn (mut client NamecomClient) hello() !HelloResponse {
	req := httpconnection.Request{
		method: .get
		prefix: '/hello'
	}
	mut http_client := client.httpclient()!
	return http_client.get_json_generic[HelloResponse](req)!
}

//
// Domain Operations
//

// list_domains returns all domains in the account
pub fn (mut client NamecomClient) list_domains() ![]Domain {
	req := httpconnection.Request{
		method: .get
		prefix: '/domains'
	}
	mut http_client := client.httpclient()!
	r := http_client.get_json_generic[DomainListResponse](req)!
	return r.domains
}

// get_domain returns details about a specific domain
pub fn (mut client NamecomClient) get_domain(domain_name string) !Domain {
	req := httpconnection.Request{
		method: .get
		prefix: '/domains/${domain_name}'
	}
	mut http_client := client.httpclient()!
	return http_client.get_json_generic[Domain](req)!
}

// lock_domain locks a domain to prevent transfers
pub fn (mut client NamecomClient) lock_domain(domain_name string) !Domain {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains/${domain_name}:lock'
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Domain](req)!
}

// unlock_domain unlocks a domain to allow transfers
pub fn (mut client NamecomClient) unlock_domain(domain_name string) !Domain {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains/${domain_name}:unlock'
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Domain](req)!
}

// enable_autorenew enables auto-renewal for a domain
pub fn (mut client NamecomClient) enable_autorenew(domain_name string) !Domain {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains/${domain_name}:enableAutorenew'
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Domain](req)!
}

// disable_autorenew disables auto-renewal for a domain
pub fn (mut client NamecomClient) disable_autorenew(domain_name string) !Domain {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains/${domain_name}:disableAutorenew'
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Domain](req)!
}

// enable_whois_privacy enables WHOIS privacy for a domain
pub fn (mut client NamecomClient) enable_whois_privacy(domain_name string) !Domain {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains/${domain_name}:enableWhoisPrivacy'
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Domain](req)!
}

// disable_whois_privacy disables WHOIS privacy for a domain
pub fn (mut client NamecomClient) disable_whois_privacy(domain_name string) !Domain {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains/${domain_name}:disableWhoisPrivacy'
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Domain](req)!
}

// set_nameservers sets the nameservers for a domain
pub fn (mut client NamecomClient) set_nameservers(domain_name string, nameservers []string) !Domain {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains/${domain_name}:setNameservers'
		data:       json.encode(SetNameserversRequest{ nameservers: nameservers })
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Domain](req)!
}

// set_contacts sets the contacts for a domain
pub fn (mut client NamecomClient) set_contacts(domain_name string, contacts Contacts) !Domain {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains/${domain_name}:setContacts'
		data:       json.encode(SetContactsRequest{ contacts: contacts })
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Domain](req)!
}

// check_availability checks if domains are available for purchase
pub fn (mut client NamecomClient) check_availability(domain_names []string) ![]SearchResult {
	data := json.encode({
		'domainNames': domain_names
	})
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains:checkAvailability'
		data:       data
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	r := http_client.post_json_generic[SearchResponse](req)!
	return r.results
}

// search searches for available domains by keyword
pub fn (mut client NamecomClient) search(keyword string) ![]SearchResult {
	data := json.encode({
		'keyword': keyword
	})
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains:search'
		data:       data
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	r := http_client.post_json_generic[SearchResponse](req)!
	return r.results
}

//
// DNS Record Operations
//

// list_records returns all DNS records for a domain
pub fn (mut client NamecomClient) list_records(domain_name string) ![]DNSRecord {
	req := httpconnection.Request{
		method: .get
		prefix: '/domains/${domain_name}/records'
	}
	mut http_client := client.httpclient()!
	r := http_client.get_json_generic[RecordListResponse](req)!
	return r.records
}

// get_record returns a specific DNS record
pub fn (mut client NamecomClient) get_record(domain_name string, record_id int) !DNSRecord {
	req := httpconnection.Request{
		method: .get
		prefix: '/domains/${domain_name}/records/${record_id}'
	}
	mut http_client := client.httpclient()!
	return http_client.get_json_generic[DNSRecord](req)!
}

// create_record creates a new DNS record
pub fn (mut client NamecomClient) create_record(domain_name string, record CreateRecordRequest) !DNSRecord {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/domains/${domain_name}/records'
		data:       json.encode(record)
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[DNSRecord](req)!
}

// update_record updates an existing DNS record
pub fn (mut client NamecomClient) update_record(domain_name string, record_id int, record UpdateRecordRequest) !DNSRecord {
	req := httpconnection.Request{
		method:     .put
		prefix:     '/domains/${domain_name}/records/${record_id}'
		data:       json.encode(record)
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	result := http_client.send(req)!
	if !result.is_ok() {
		return error('Could not update record: ${result.data}')
	}
	return json.decode(DNSRecord, result.data)!
}

// delete_record deletes a DNS record
pub fn (mut client NamecomClient) delete_record(domain_name string, record_id int) ! {
	req := httpconnection.Request{
		method: .delete
		prefix: '/domains/${domain_name}/records/${record_id}'
	}
	mut http_client := client.httpclient()!
	result := http_client.send(req)!
	if !result.is_ok() {
		return error('Could not delete record: ${result.data}')
	}
}
