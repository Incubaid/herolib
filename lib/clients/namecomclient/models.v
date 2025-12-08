module namecomclient

// Domain represents a domain in the Name.com account
pub struct Domain {
pub:
	domain_name      string   @[json: 'domainName']
	nameservers      []string
	contacts         ?Contacts
	privacy_enabled  bool   @[json: 'privacyEnabled']
	locked           bool
	autorenew_enabled bool  @[json: 'autorenewEnabled']
	expire_date      string @[json: 'expireDate']
	create_date      string @[json: 'createDate']
	renewal_price    f64    @[json: 'renewalPrice']
}

// Contacts contains all contact types for a domain
pub struct Contacts {
pub:
	registrant ?Contact
	admin      ?Contact
	tech       ?Contact
	billing    ?Contact
}

// Contact represents contact information
pub struct Contact {
pub:
	first_name   string @[json: 'firstName']
	last_name    string @[json: 'lastName']
	company_name string @[json: 'companyName']
	address1     string
	address2     string
	city         string
	state        string
	zip          string
	country      string
	phone        string
	fax          string
	email        string
}

// DomainListResponse is the response from ListDomains
pub struct DomainListResponse {
pub:
	domains      []Domain
	current_page int @[json: 'currentPage']
	next_page    int @[json: 'nextPage']
	last_page    int @[json: 'lastPage']
	total_count  int @[json: 'totalCount']
}

// DNSRecord represents a DNS record
pub struct DNSRecord {
pub:
	id          int
	domain_name string @[json: 'domainName']
	host        string
	fqdn        string
	record_type string @[json: 'type']
	answer      string
	ttl         u32
	priority    u32
}

// RecordListResponse is the response from ListRecords
pub struct RecordListResponse {
pub:
	records   []DNSRecord
	next_page int @[json: 'nextPage']
	last_page int @[json: 'lastPage']
}

// CreateRecordRequest is the request body for creating a DNS record
pub struct CreateRecordRequest {
pub:
	host        string
	record_type string @[json: 'type']
	answer      string
	ttl         u32
	priority    u32
}

// UpdateRecordRequest is the request body for updating a DNS record
pub struct UpdateRecordRequest {
pub:
	host        string
	record_type string @[json: 'type']
	answer      string
	ttl         u32
	priority    u32
}

// SearchResult represents a domain search result
pub struct SearchResult {
pub:
	domain_name   string @[json: 'domainName']
	sld           string
	tld           string
	purchasable   bool
	premium       bool
	purchase_price f64   @[json: 'purchasePrice']
	purchase_type  string @[json: 'purchaseType']
	renewal_price  f64   @[json: 'renewalPrice']
}

// SearchResponse is the response from Search or CheckAvailability
pub struct SearchResponse {
pub:
	results []SearchResult
}

// HelloResponse is the response from the hello endpoint
pub struct HelloResponse {
pub:
	server_name string @[json: 'serverName']
	motd        string
	username    string
}

// APIError represents an error response from the API
pub struct APIError {
pub:
	message string
	details string
}

// SetNameserversRequest is the request body for setting nameservers
pub struct SetNameserversRequest {
pub:
	nameservers []string
}

// SetContactsRequest is the request body for setting contacts
pub struct SetContactsRequest {
pub:
	contacts Contacts
}
