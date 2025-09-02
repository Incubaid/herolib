module business

// CompanyStatus represents the lifecycle of a company
pub enum CompanyStatus {
	pending_payment // Company created but payment not completed
	active          // Payment completed, company is active
	suspended       // Company suspended (e.g., payment issues)
	inactive        // Company deactivated
}

// BusinessType represents the type of business
pub enum BusinessType {
	coop    // Cooperative
	single  // Single entity
	twin    // Twin entity
	starter // Starter business
	global  // Global business
}

// Company represents a business entity
@[heap]
pub struct Company {
pub mut:
	id                  u32           // Unique company ID
	name                string        // Company name
	registration_number string        // Official registration number
	incorporation_date  i64           // Incorporation date timestamp
	fiscal_year_end     string        // Fiscal year end (e.g., "MM-DD")
	email               string        // Company email
	phone               string        // Company phone
	website             string        // Company website
	address             string        // Company address
	business_type       BusinessType  // Type of business
	industry            string        // Industry sector
	description         string        // Company description
	status              CompanyStatus // Current status
	created_at          u64           // Creation timestamp
	updated_at          u64           // Last update timestamp
}

// new creates a new Company with default values
pub fn Company.new() Company {
	return Company{
		id: 0
		name: ''
		registration_number: ''
		incorporation_date: 0
		fiscal_year_end: ''
		email: ''
		phone: ''
		website: ''
		address: ''
		business_type: .single
		industry: ''
		description: ''
		status: .pending_payment
		created_at: 0
		updated_at: 0
	}
}

// name sets the company name (builder pattern)
pub fn (mut c Company) name(name string) Company {
	c.name = name
	return c
}

// registration_number sets the registration number (builder pattern)
pub fn (mut c Company) registration_number(registration_number string) Company {
	c.registration_number = registration_number
	return c
}

// incorporation_date sets the incorporation date (builder pattern)
pub fn (mut c Company) incorporation_date(incorporation_date i64) Company {
	c.incorporation_date = incorporation_date
	return c
}

// fiscal_year_end sets the fiscal year end (builder pattern)
pub fn (mut c Company) fiscal_year_end(fiscal_year_end string) Company {
	c.fiscal_year_end = fiscal_year_end
	return c
}

// email sets the company email (builder pattern)
pub fn (mut c Company) email(email string) Company {
	c.email = email
	return c
}

// phone sets the company phone (builder pattern)
pub fn (mut c Company) phone(phone string) Company {
	c.phone = phone
	return c
}

// website sets the company website (builder pattern)
pub fn (mut c Company) website(website string) Company {
	c.website = website
	return c
}

// address sets the company address (builder pattern)
pub fn (mut c Company) address(address string) Company {
	c.address = address
	return c
}

// business_type sets the business type (builder pattern)
pub fn (mut c Company) business_type(business_type BusinessType) Company {
	c.business_type = business_type
	return c
}

// industry sets the industry (builder pattern)
pub fn (mut c Company) industry(industry string) Company {
	c.industry = industry
	return c
}

// description sets the description (builder pattern)
pub fn (mut c Company) description(description string) Company {
	c.description = description
	return c
}

// status sets the status (builder pattern)
pub fn (mut c Company) status(status CompanyStatus) Company {
	c.status = status
	return c
}

// is_active returns true if the company is active
pub fn (c Company) is_active() bool {
	return c.status == .active
}

// is_pending_payment returns true if the company is pending payment
pub fn (c Company) is_pending_payment() bool {
	return c.status == .pending_payment
}

// is_suspended returns true if the company is suspended
pub fn (c Company) is_suspended() bool {
	return c.status == .suspended
}

// is_inactive returns true if the company is inactive
pub fn (c Company) is_inactive() bool {
	return c.status == .inactive
}

// activate activates the company
pub fn (mut c Company) activate() {
	c.status = .active
}

// suspend suspends the company
pub fn (mut c Company) suspend() {
	c.status = .suspended
}

// deactivate deactivates the company
pub fn (mut c Company) deactivate() {
	c.status = .inactive
}

// business_type_string returns the business type as a string
pub fn (c Company) business_type_string() string {
	return match c.business_type {
		.coop { 'Coop' }
		.single { 'Single' }
		.twin { 'Twin' }
		.starter { 'Starter' }
		.global { 'Global' }
	}
}

// status_string returns the status as a string
pub fn (c Company) status_string() string {
	return match c.status {
		.pending_payment { 'Pending Payment' }
		.active { 'Active' }
		.suspended { 'Suspended' }
		.inactive { 'Inactive' }
	}
}