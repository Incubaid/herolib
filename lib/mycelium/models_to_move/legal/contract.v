module legal

import time

// ContractStatus defines the possible statuses of a contract
pub enum ContractStatus {
	draft              // Contract is in draft state
	pending_signatures // Waiting for signatures
	signed             // All parties have signed
	active             // Contract is active
	expired            // Contract has expired
	cancelled          // Contract was cancelled
}

// SignerStatus defines the status of a contract signer
pub enum SignerStatus {
	pending  // Signature is pending
	signed   // Signer has signed
	rejected // Signer rejected the contract
}

// ContractRevision represents a version of the contract content
pub struct ContractRevision {
pub mut:
	version    u32     // Version number
	content    string  // Contract content for this version
	created_at u64     // Creation timestamp
	created_by string  // Who created this revision
	comments   ?string // Optional comments about this revision
}

// new creates a new ContractRevision
pub fn ContractRevision.new(version u32, content string, created_by string) ContractRevision {
	return ContractRevision{
		version:    version
		content:    content
		created_at: u64(time.now().unix_time())
		created_by: created_by
		comments:   none
	}
}

// comments sets comments for the revision (builder pattern)
pub fn (mut cr ContractRevision) comments(comments string) ContractRevision {
	cr.comments = comments
	return cr
}

// ContractSigner represents a party involved in signing a contract
pub struct ContractSigner {
pub mut:
	id                         string       // Unique ID for the signer (UUID string)
	name                       string       // Signer's name
	email                      string       // Signer's email
	status                     SignerStatus // Current status
	signed_at                  ?u64         // When they signed (optional)
	comments                   ?string      // Optional comments from signer
	last_reminder_mail_sent_at ?u64         // Last reminder timestamp
	signature_data             ?string      // Base64 encoded signature image data
}

// new creates a new ContractSigner
pub fn ContractSigner.new(id string, name string, email string) ContractSigner {
	return ContractSigner{
		id:                         id
		name:                       name
		email:                      email
		status:                     .pending
		signed_at:                  none
		comments:                   none
		last_reminder_mail_sent_at: none
		signature_data:             none
	}
}

// status sets the signer status (builder pattern)
pub fn (mut cs ContractSigner) status(status SignerStatus) ContractSigner {
	cs.status = status
	return cs
}

// signed_at sets the signing timestamp (builder pattern)
pub fn (mut cs ContractSigner) signed_at(signed_at u64) ContractSigner {
	cs.signed_at = signed_at
	return cs
}

// comments sets comments (builder pattern)
pub fn (mut cs ContractSigner) comments(comments string) ContractSigner {
	cs.comments = comments
	return cs
}

// signature_data sets the signature data (builder pattern)
pub fn (mut cs ContractSigner) signature_data(signature_data string) ContractSigner {
	cs.signature_data = signature_data
	return cs
}

// can_send_reminder checks if a reminder can be sent (30-minute rate limiting)
pub fn (cs ContractSigner) can_send_reminder() bool {
	current_time := u64(time.now().unix_time())
	if last_sent := cs.last_reminder_mail_sent_at {
		thirty_minutes := u64(30 * 60) // 30 minutes in seconds
		return current_time >= last_sent + thirty_minutes
	}
	return true // No reminder sent yet
}

// reminder_cooldown_remaining gets remaining cooldown time in seconds
pub fn (cs ContractSigner) reminder_cooldown_remaining() ?u64 {
	current_time := u64(time.now().unix_time())
	if last_sent := cs.last_reminder_mail_sent_at {
		thirty_minutes := u64(30 * 60)
		cooldown_end := last_sent + thirty_minutes
		if current_time < cooldown_end {
			return cooldown_end - current_time
		}
	}
	return none // No cooldown
}

// mark_reminder_sent updates the reminder timestamp to current time
pub fn (mut cs ContractSigner) mark_reminder_sent() {
	cs.last_reminder_mail_sent_at = u64(time.now().unix_time())
}

// sign signs the contract with optional signature data and comments
pub fn (mut cs ContractSigner) sign(signature_data ?string, comments ?string) {
	cs.status = .signed
	cs.signed_at = u64(time.now().unix_time())
	cs.signature_data = signature_data
	if comment := comments {
		cs.comments = comment
	}
}

// Contract represents a legal agreement
@[heap]
pub struct Contract {
pub mut:
	id                   u32                // Unique contract ID
	contract_id          string             // Unique UUID for the contract
	title                string             // Contract title
	description          string             // Contract description
	contract_type        string             // Type of contract
	status               ContractStatus     // Current status
	created_by           string             // Who created the contract
	terms_and_conditions string             // Terms and conditions text
	start_date           ?u64               // Optional start date
	end_date             ?u64               // Optional end date
	renewal_period_days  ?i32               // Optional renewal period in days
	next_renewal_date    ?u64               // Optional next renewal date
	signers              []ContractSigner   // List of signers
	revisions            []ContractRevision // Contract revisions
	current_version      u32                // Current version number
	last_signed_date     ?u64               // Last signing date
	created_at           u64                // Creation timestamp
	updated_at           u64                // Last update timestamp
}

// new creates a new Contract
pub fn Contract.new(contract_id string) Contract {
	now := u64(time.now().unix_time())
	return Contract{
		id:                   0
		contract_id:          contract_id
		title:                ''
		description:          ''
		contract_type:        ''
		status:               .draft
		created_by:           ''
		terms_and_conditions: ''
		start_date:           none
		end_date:             none
		renewal_period_days:  none
		next_renewal_date:    none
		signers:              []
		revisions:            []
		current_version:      0
		last_signed_date:     none
		created_at:           now
		updated_at:           now
	}
}

// title sets the contract title (builder pattern)
pub fn (mut c Contract) title(title string) Contract {
	c.title = title
	return c
}

// description sets the contract description (builder pattern)
pub fn (mut c Contract) description(description string) Contract {
	c.description = description
	return c
}

// contract_type sets the contract type (builder pattern)
pub fn (mut c Contract) contract_type(contract_type string) Contract {
	c.contract_type = contract_type
	return c
}

// status sets the contract status (builder pattern)
pub fn (mut c Contract) status(status ContractStatus) Contract {
	c.status = status
	return c
}

// created_by sets who created the contract (builder pattern)
pub fn (mut c Contract) created_by(created_by string) Contract {
	c.created_by = created_by
	return c
}

// terms_and_conditions sets the terms (builder pattern)
pub fn (mut c Contract) terms_and_conditions(terms string) Contract {
	c.terms_and_conditions = terms
	return c
}

// start_date sets the start date (builder pattern)
pub fn (mut c Contract) start_date(start_date u64) Contract {
	c.start_date = start_date
	return c
}

// end_date sets the end date (builder pattern)
pub fn (mut c Contract) end_date(end_date u64) Contract {
	c.end_date = end_date
	return c
}

// renewal_period_days sets the renewal period (builder pattern)
pub fn (mut c Contract) renewal_period_days(days i32) Contract {
	c.renewal_period_days = days
	return c
}

// next_renewal_date sets the next renewal date (builder pattern)
pub fn (mut c Contract) next_renewal_date(date u64) Contract {
	c.next_renewal_date = date
	return c
}

// add_signer adds a signer to the contract (builder pattern)
pub fn (mut c Contract) add_signer(signer ContractSigner) Contract {
	c.signers << signer
	return c
}

// signers sets all signers (builder pattern)
pub fn (mut c Contract) signers(signers []ContractSigner) Contract {
	c.signers = signers
	return c
}

// add_revision adds a revision to the contract (builder pattern)
pub fn (mut c Contract) add_revision(revision ContractRevision) Contract {
	c.revisions << revision
	return c
}

// revisions sets all revisions (builder pattern)
pub fn (mut c Contract) revisions(revisions []ContractRevision) Contract {
	c.revisions = revisions
	return c
}

// current_version sets the current version (builder pattern)
pub fn (mut c Contract) current_version(version u32) Contract {
	c.current_version = version
	return c
}

// last_signed_date sets the last signed date (builder pattern)
pub fn (mut c Contract) last_signed_date(date u64) Contract {
	c.last_signed_date = date
	return c
}

// set_status sets the contract status and updates timestamp
pub fn (mut c Contract) set_status(status ContractStatus) {
	c.status = status
	c.updated_at = u64(time.now().unix_time())
}

// is_draft checks if contract is in draft status
pub fn (c Contract) is_draft() bool {
	return c.status == .draft
}

// is_pending_signatures checks if contract is pending signatures
pub fn (c Contract) is_pending_signatures() bool {
	return c.status == .pending_signatures
}

// is_signed checks if contract is signed
pub fn (c Contract) is_signed() bool {
	return c.status == .signed
}

// is_active checks if contract is active
pub fn (c Contract) is_active() bool {
	return c.status == .active
}

// is_expired checks if contract is expired
pub fn (c Contract) is_expired() bool {
	return c.status == .expired
}

// is_cancelled checks if contract is cancelled
pub fn (c Contract) is_cancelled() bool {
	return c.status == .cancelled
}

// get_pending_signers returns signers with pending status
pub fn (c Contract) get_pending_signers() []ContractSigner {
	return c.signers.filter(it.status == .pending)
}

// get_signed_signers returns signers who have signed
pub fn (c Contract) get_signed_signers() []ContractSigner {
	return c.signers.filter(it.status == .signed)
}

// all_signed checks if all signers have signed
pub fn (c Contract) all_signed() bool {
	if c.signers.len == 0 {
		return false
	}

	for signer in c.signers {
		if signer.status != .signed {
			return false
		}
	}
	return true
}

// get_signer_by_id finds a signer by ID
pub fn (c Contract) get_signer_by_id(id string) ?ContractSigner {
	for signer in c.signers {
		if signer.id == id {
			return signer
		}
	}
	return none
}

// get_current_revision gets the current revision
pub fn (c Contract) get_current_revision() ?ContractRevision {
	for revision in c.revisions {
		if revision.version == c.current_version {
			return revision
		}
	}
	return none
}

// status_string returns the status as a string
pub fn (c Contract) status_string() string {
	return match c.status {
		.draft { 'Draft' }
		.pending_signatures { 'Pending Signatures' }
		.signed { 'Signed' }
		.active { 'Active' }
		.expired { 'Expired' }
		.cancelled { 'Cancelled' }
	}
}
