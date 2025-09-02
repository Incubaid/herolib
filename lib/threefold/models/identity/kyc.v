module identity

// IdenfyWebhookEvent represents an iDenfy webhook event structure
pub struct IdenfyWebhookEvent {
pub mut:
	client_id       string                    // Client ID
	scan_ref        string                    // Scan reference
	status          string                    // Verification status
	platform        string                    // Platform used
	started_at      string                    // When verification started
	finished_at     ?string                   // When verification finished (optional)
	client_ip       ?string                   // Client IP address (optional)
	client_location ?string                   // Client location (optional)
	data            ?IdenfyVerificationData   // Verification data (optional)
}

// IdenfyVerificationData represents the verification data from iDenfy
pub struct IdenfyVerificationData {
pub mut:
	doc_first_name         ?string // First name from document
	doc_last_name          ?string // Last name from document
	doc_number             ?string // Document number
	doc_personal_code      ?string // Personal code from document
	doc_expiry             ?string // Document expiry date
	doc_dob                ?string // Date of birth from document
	doc_type               ?string // Document type
	doc_sex                ?string // Sex from document
	doc_nationality        ?string // Nationality from document
	doc_issuing_country    ?string // Document issuing country
	manually_data_changed  ?bool   // Whether data was manually changed
}

// new creates a new IdenfyWebhookEvent
pub fn IdenfyWebhookEvent.new() IdenfyWebhookEvent {
	return IdenfyWebhookEvent{
		client_id: ''
		scan_ref: ''
		status: ''
		platform: ''
		started_at: ''
		finished_at: none
		client_ip: none
		client_location: none
		data: none
	}
}

// client_id sets the client ID (builder pattern)
pub fn (mut event IdenfyWebhookEvent) client_id(client_id string) IdenfyWebhookEvent {
	event.client_id = client_id
	return event
}

// scan_ref sets the scan reference (builder pattern)
pub fn (mut event IdenfyWebhookEvent) scan_ref(scan_ref string) IdenfyWebhookEvent {
	event.scan_ref = scan_ref
	return event
}

// status sets the status (builder pattern)
pub fn (mut event IdenfyWebhookEvent) status(status string) IdenfyWebhookEvent {
	event.status = status
	return event
}

// platform sets the platform (builder pattern)
pub fn (mut event IdenfyWebhookEvent) platform(platform string) IdenfyWebhookEvent {
	event.platform = platform
	return event
}

// started_at sets the started timestamp (builder pattern)
pub fn (mut event IdenfyWebhookEvent) started_at(started_at string) IdenfyWebhookEvent {
	event.started_at = started_at
	return event
}

// finished_at sets the finished timestamp (builder pattern)
pub fn (mut event IdenfyWebhookEvent) finished_at(finished_at ?string) IdenfyWebhookEvent {
	event.finished_at = finished_at
	return event
}

// client_ip sets the client IP (builder pattern)
pub fn (mut event IdenfyWebhookEvent) client_ip(client_ip ?string) IdenfyWebhookEvent {
	event.client_ip = client_ip
	return event
}

// client_location sets the client location (builder pattern)
pub fn (mut event IdenfyWebhookEvent) client_location(client_location ?string) IdenfyWebhookEvent {
	event.client_location = client_location
	return event
}

// data sets the verification data (builder pattern)
pub fn (mut event IdenfyWebhookEvent) data(data ?IdenfyVerificationData) IdenfyWebhookEvent {
	event.data = data
	return event
}

// new creates a new IdenfyVerificationData
pub fn IdenfyVerificationData.new() IdenfyVerificationData {
	return IdenfyVerificationData{
		doc_first_name: none
		doc_last_name: none
		doc_number: none
		doc_personal_code: none
		doc_expiry: none
		doc_dob: none
		doc_type: none
		doc_sex: none
		doc_nationality: none
		doc_issuing_country: none
		manually_data_changed: none
	}
}

// doc_first_name sets the first name (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_first_name(doc_first_name ?string) IdenfyVerificationData {
	data.doc_first_name = doc_first_name
	return data
}

// doc_last_name sets the last name (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_last_name(doc_last_name ?string) IdenfyVerificationData {
	data.doc_last_name = doc_last_name
	return data
}

// doc_number sets the document number (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_number(doc_number ?string) IdenfyVerificationData {
	data.doc_number = doc_number
	return data
}

// doc_personal_code sets the personal code (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_personal_code(doc_personal_code ?string) IdenfyVerificationData {
	data.doc_personal_code = doc_personal_code
	return data
}

// doc_expiry sets the document expiry (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_expiry(doc_expiry ?string) IdenfyVerificationData {
	data.doc_expiry = doc_expiry
	return data
}

// doc_dob sets the date of birth (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_dob(doc_dob ?string) IdenfyVerificationData {
	data.doc_dob = doc_dob
	return data
}

// doc_type sets the document type (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_type(doc_type ?string) IdenfyVerificationData {
	data.doc_type = doc_type
	return data
}

// doc_sex sets the sex (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_sex(doc_sex ?string) IdenfyVerificationData {
	data.doc_sex = doc_sex
	return data
}

// doc_nationality sets the nationality (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_nationality(doc_nationality ?string) IdenfyVerificationData {
	data.doc_nationality = doc_nationality
	return data
}

// doc_issuing_country sets the issuing country (builder pattern)
pub fn (mut data IdenfyVerificationData) doc_issuing_country(doc_issuing_country ?string) IdenfyVerificationData {
	data.doc_issuing_country = doc_issuing_country
	return data
}

// manually_data_changed sets whether data was manually changed (builder pattern)
pub fn (mut data IdenfyVerificationData) manually_data_changed(manually_data_changed ?bool) IdenfyVerificationData {
	data.manually_data_changed = manually_data_changed
	return data
}

// is_approved checks if the verification was approved
pub fn (event IdenfyWebhookEvent) is_approved() bool {
	return event.status.to_lower() == 'approved'
}

// is_rejected checks if the verification was rejected
pub fn (event IdenfyWebhookEvent) is_rejected() bool {
	return event.status.to_lower() == 'rejected'
}

// is_pending checks if the verification is pending
pub fn (event IdenfyWebhookEvent) is_pending() bool {
	return event.status.to_lower() == 'pending'
}

// has_finished checks if the verification has finished
pub fn (event IdenfyWebhookEvent) has_finished() bool {
	return event.finished_at != none
}

// get_full_name returns the full name from verification data
pub fn (event IdenfyWebhookEvent) get_full_name() string {
	if data := event.data {
		first_name := data.doc_first_name or { '' }
		last_name := data.doc_last_name or { '' }
		return '${first_name} ${last_name}'.trim_space()
	}
	return ''
}

// get_document_info returns formatted document information
pub fn (event IdenfyWebhookEvent) get_document_info() string {
	if data := event.data {
		doc_type := data.doc_type or { 'Unknown' }
		doc_number := data.doc_number or { 'N/A' }
		return '${doc_type}: ${doc_number}'
	}
	return 'No document information'
}