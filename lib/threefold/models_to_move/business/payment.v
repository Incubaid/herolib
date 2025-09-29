module business

import time

// PaymentStatus represents the status of a payment
pub enum PaymentStatus {
	pending    // Payment is pending
	processing // Payment is being processed
	completed  // Payment has been completed
	failed     // Payment has failed
	refunded   // Payment has been refunded
}

// Payment represents a financial transaction
@[heap]
pub struct Payment {
pub mut:
	id                 u32           // Unique payment ID
	payment_intent_id  string        // Stripe payment intent ID for tracking
	company_id         u32           // Reference to the company this payment is for
	payment_plan       string        // Payment plan ("monthly", "yearly", "two_year")
	setup_fee          f64           // Setup fee amount
	monthly_fee        f64           // Monthly fee amount
	total_amount       f64           // Total payment amount
	currency           string        // Currency code (e.g., "usd")
	status             PaymentStatus // Payment status
	stripe_customer_id ?string       // Optional Stripe customer ID
	created_at         i64           // Creation timestamp
	completed_at       ?i64          // Completion timestamp
	updated_at         u64           // Last update timestamp
}

// new creates a new Payment
pub fn Payment.new(payment_intent_id string, company_id u32, payment_plan string, setup_fee f64, monthly_fee f64, total_amount f64) Payment {
	now := time.now().unix_time()
	return Payment{
		id:                 0
		payment_intent_id:  payment_intent_id
		company_id:         company_id
		payment_plan:       payment_plan
		setup_fee:          setup_fee
		monthly_fee:        monthly_fee
		total_amount:       total_amount
		currency:           'usd'
		status:             .pending
		stripe_customer_id: none
		created_at:         now
		completed_at:       none
		updated_at:         u64(now)
	}
}

// payment_intent_id sets the payment intent ID (builder pattern)
pub fn (mut p Payment) payment_intent_id(payment_intent_id string) Payment {
	p.payment_intent_id = payment_intent_id
	return p
}

// company_id sets the company ID (builder pattern)
pub fn (mut p Payment) company_id(company_id u32) Payment {
	p.company_id = company_id
	return p
}

// payment_plan sets the payment plan (builder pattern)
pub fn (mut p Payment) payment_plan(payment_plan string) Payment {
	p.payment_plan = payment_plan
	return p
}

// setup_fee sets the setup fee (builder pattern)
pub fn (mut p Payment) setup_fee(setup_fee f64) Payment {
	p.setup_fee = setup_fee
	return p
}

// monthly_fee sets the monthly fee (builder pattern)
pub fn (mut p Payment) monthly_fee(monthly_fee f64) Payment {
	p.monthly_fee = monthly_fee
	return p
}

// total_amount sets the total amount (builder pattern)
pub fn (mut p Payment) total_amount(total_amount f64) Payment {
	p.total_amount = total_amount
	return p
}

// status sets the status (builder pattern)
pub fn (mut p Payment) status(status PaymentStatus) Payment {
	p.status = status
	return p
}

// stripe_customer_id sets the Stripe customer ID (builder pattern)
pub fn (mut p Payment) stripe_customer_id(stripe_customer_id ?string) Payment {
	p.stripe_customer_id = stripe_customer_id
	return p
}

// currency sets the currency (builder pattern)
pub fn (mut p Payment) currency(currency string) Payment {
	p.currency = currency
	return p
}

// created_at sets the creation timestamp (builder pattern)
pub fn (mut p Payment) created_at(created_at i64) Payment {
	p.created_at = created_at
	return p
}

// completed_at sets the completion timestamp (builder pattern)
pub fn (mut p Payment) completed_at(completed_at ?i64) Payment {
	p.completed_at = completed_at
	return p
}

// complete_payment completes the payment with optional Stripe customer ID
pub fn (mut p Payment) complete_payment(stripe_customer_id ?string) Payment {
	p.status = .completed
	p.stripe_customer_id = stripe_customer_id
	p.completed_at = time.now().unix_time()
	p.updated_at = u64(time.now().unix_time())
	return p
}

// process_payment marks payment as processing
pub fn (mut p Payment) process_payment() Payment {
	p.status = .processing
	p.updated_at = u64(time.now().unix_time())
	return p
}

// fail_payment marks payment as failed
pub fn (mut p Payment) fail_payment() Payment {
	p.status = .failed
	p.updated_at = u64(time.now().unix_time())
	return p
}

// refund_payment refunds the payment
pub fn (mut p Payment) refund_payment() Payment {
	p.status = .refunded
	p.updated_at = u64(time.now().unix_time())
	return p
}

// is_completed checks if payment is completed
pub fn (p Payment) is_completed() bool {
	return p.status == .completed
}

// is_pending checks if payment is pending
pub fn (p Payment) is_pending() bool {
	return p.status == .pending
}

// is_processing checks if payment is processing
pub fn (p Payment) is_processing() bool {
	return p.status == .processing
}

// has_failed checks if payment has failed
pub fn (p Payment) has_failed() bool {
	return p.status == .failed
}

// is_refunded checks if payment is refunded
pub fn (p Payment) is_refunded() bool {
	return p.status == .refunded
}

// status_string returns the status as a string
pub fn (p Payment) status_string() string {
	return match p.status {
		.pending { 'Pending' }
		.processing { 'Processing' }
		.completed { 'Completed' }
		.failed { 'Failed' }
		.refunded { 'Refunded' }
	}
}

// is_monthly_plan checks if this is a monthly payment plan
pub fn (p Payment) is_monthly_plan() bool {
	return p.payment_plan == 'monthly'
}

// is_yearly_plan checks if this is a yearly payment plan
pub fn (p Payment) is_yearly_plan() bool {
	return p.payment_plan == 'yearly'
}

// is_two_year_plan checks if this is a two-year payment plan
pub fn (p Payment) is_two_year_plan() bool {
	return p.payment_plan == 'two_year'
}
