module flow

// SignatureRequirement represents a signature requirement for a flow step
@[heap]
pub struct SignatureRequirement {
pub mut:
	id           u32     // Unique signature requirement ID
	flow_step_id u32     // Foreign key to the FlowStep this requirement belongs to
	public_key   string  // The public key required to sign the message
	message      string  // The plaintext message to be signed
	signed_by    ?string // The public key of the entity that signed the message, if signed
	signature    ?string // The signature, if signed
	status       string  // Current status of the signature requirement (e.g., "Pending", "SentToClient", "Signed", "Failed", "Error")
	created_at   u64     // Creation timestamp
	updated_at   u64     // Last update timestamp
}

// new creates a new signature requirement
pub fn SignatureRequirement.new(flow_step_id u32, public_key string, message string) SignatureRequirement {
	return SignatureRequirement{
		id: 0
		flow_step_id: flow_step_id
		public_key: public_key
		message: message
		signed_by: none
		signature: none
		status: 'Pending'
		created_at: 0
		updated_at: 0
	}
}

// signed_by sets the public key of the signer (builder pattern)
pub fn (mut sr SignatureRequirement) signed_by(signed_by string) SignatureRequirement {
	sr.signed_by = signed_by
	return sr
}

// signature sets the signature (builder pattern)
pub fn (mut sr SignatureRequirement) signature(signature string) SignatureRequirement {
	sr.signature = signature
	return sr
}

// status sets the status (builder pattern)
pub fn (mut sr SignatureRequirement) status(status string) SignatureRequirement {
	sr.status = status
	return sr
}

// is_pending returns true if the signature requirement is pending
pub fn (sr SignatureRequirement) is_pending() bool {
	return sr.status == 'Pending'
}

// is_sent_to_client returns true if the signature requirement has been sent to client
pub fn (sr SignatureRequirement) is_sent_to_client() bool {
	return sr.status == 'SentToClient'
}

// is_signed returns true if the signature requirement has been signed
pub fn (sr SignatureRequirement) is_signed() bool {
	return sr.status == 'Signed'
}

// is_failed returns true if the signature requirement has failed
pub fn (sr SignatureRequirement) is_failed() bool {
	return sr.status == 'Failed'
}

// has_error returns true if the signature requirement has an error
pub fn (sr SignatureRequirement) has_error() bool {
	return sr.status == 'Error'
}

// send_to_client marks the requirement as sent to client
pub fn (mut sr SignatureRequirement) send_to_client() {
	sr.status = 'SentToClient'
}

// sign completes the signature requirement with signature data
pub fn (mut sr SignatureRequirement) sign(signed_by string, signature string) {
	sr.signed_by = signed_by
	sr.signature = signature
	sr.status = 'Signed'
}

// fail marks the signature requirement as failed
pub fn (mut sr SignatureRequirement) fail() {
	sr.status = 'Failed'
}

// error marks the signature requirement as having an error
pub fn (mut sr SignatureRequirement) error() {
	sr.status = 'Error'
}

// reset resets the signature requirement to pending status
pub fn (mut sr SignatureRequirement) reset() {
	sr.signed_by = none
	sr.signature = none
	sr.status = 'Pending'
}

// validate_signature validates that the signature matches the expected public key
// TODO: implement actual cryptographic validation
pub fn (sr SignatureRequirement) validate_signature() bool {
	if signed_by := sr.signed_by {
		if signature := sr.signature {
			// TODO: implement actual signature validation
			return signed_by == sr.public_key && signature.len > 0
		}
	}
	return false
}