module payment

// StripeWebhookEvent represents a Stripe webhook event structure
pub struct StripeWebhookEvent {
pub mut:
	id               string              // Event ID
	object           string              // Object type (always "event")
	api_version      ?string             // API version used
	created          i64                 // Creation timestamp
	data             StripeEventData     // Event data
	livemode         bool                // Whether this is a live mode event
	pending_webhooks i32                 // Number of pending webhooks
	request          ?StripeEventRequest // Request information (optional)
	event_type       string              // Type of event (e.g., "payment_intent.succeeded")
}

// StripeEventData represents the data portion of a Stripe event
pub struct StripeEventData {
pub mut:
	object              string  // The main object data (JSON as string for flexibility)
	previous_attributes ?string // Previous attributes if this is an update (JSON as string)
}

// StripeEventRequest represents request information for a Stripe event
pub struct StripeEventRequest {
pub mut:
	id              ?string // Request ID (optional)
	idempotency_key ?string // Idempotency key (optional)
}

// new creates a new StripeWebhookEvent
pub fn StripeWebhookEvent.new() StripeWebhookEvent {
	return StripeWebhookEvent{
		id:               ''
		object:           'event'
		api_version:      none
		created:          0
		data:             StripeEventData.new()
		livemode:         false
		pending_webhooks: 0
		request:          none
		event_type:       ''
	}
}

// id sets the event ID (builder pattern)
pub fn (mut event StripeWebhookEvent) id(id string) StripeWebhookEvent {
	event.id = id
	return event
}

// object sets the object type (builder pattern)
pub fn (mut event StripeWebhookEvent) object(object string) StripeWebhookEvent {
	event.object = object
	return event
}

// api_version sets the API version (builder pattern)
pub fn (mut event StripeWebhookEvent) api_version(api_version ?string) StripeWebhookEvent {
	event.api_version = api_version
	return event
}

// created sets the creation timestamp (builder pattern)
pub fn (mut event StripeWebhookEvent) created(created i64) StripeWebhookEvent {
	event.created = created
	return event
}

// data sets the event data (builder pattern)
pub fn (mut event StripeWebhookEvent) data(data StripeEventData) StripeWebhookEvent {
	event.data = data
	return event
}

// livemode sets the livemode flag (builder pattern)
pub fn (mut event StripeWebhookEvent) livemode(livemode bool) StripeWebhookEvent {
	event.livemode = livemode
	return event
}

// pending_webhooks sets the pending webhooks count (builder pattern)
pub fn (mut event StripeWebhookEvent) pending_webhooks(pending_webhooks i32) StripeWebhookEvent {
	event.pending_webhooks = pending_webhooks
	return event
}

// request sets the request information (builder pattern)
pub fn (mut event StripeWebhookEvent) request(request ?StripeEventRequest) StripeWebhookEvent {
	event.request = request
	return event
}

// event_type sets the event type (builder pattern)
pub fn (mut event StripeWebhookEvent) event_type(event_type string) StripeWebhookEvent {
	event.event_type = event_type
	return event
}

// new creates a new StripeEventData
pub fn StripeEventData.new() StripeEventData {
	return StripeEventData{
		object:              ''
		previous_attributes: none
	}
}

// object sets the object data (builder pattern)
pub fn (mut data StripeEventData) object(object string) StripeEventData {
	data.object = object
	return data
}

// previous_attributes sets the previous attributes (builder pattern)
pub fn (mut data StripeEventData) previous_attributes(previous_attributes ?string) StripeEventData {
	data.previous_attributes = previous_attributes
	return data
}

// new creates a new StripeEventRequest
pub fn StripeEventRequest.new() StripeEventRequest {
	return StripeEventRequest{
		id:              none
		idempotency_key: none
	}
}

// id sets the request ID (builder pattern)
pub fn (mut request StripeEventRequest) id(id ?string) StripeEventRequest {
	request.id = id
	return request
}

// idempotency_key sets the idempotency key (builder pattern)
pub fn (mut request StripeEventRequest) idempotency_key(idempotency_key ?string) StripeEventRequest {
	request.idempotency_key = idempotency_key
	return request
}

// Event type helper methods
// is_payment_intent_succeeded checks if this is a payment intent succeeded event
pub fn (event StripeWebhookEvent) is_payment_intent_succeeded() bool {
	return event.event_type == 'payment_intent.succeeded'
}

// is_payment_intent_failed checks if this is a payment intent failed event
pub fn (event StripeWebhookEvent) is_payment_intent_failed() bool {
	return event.event_type == 'payment_intent.payment_failed'
}

// is_payment_intent_created checks if this is a payment intent created event
pub fn (event StripeWebhookEvent) is_payment_intent_created() bool {
	return event.event_type == 'payment_intent.created'
}

// is_customer_created checks if this is a customer created event
pub fn (event StripeWebhookEvent) is_customer_created() bool {
	return event.event_type == 'customer.created'
}

// is_customer_updated checks if this is a customer updated event
pub fn (event StripeWebhookEvent) is_customer_updated() bool {
	return event.event_type == 'customer.updated'
}

// is_invoice_payment_succeeded checks if this is an invoice payment succeeded event
pub fn (event StripeWebhookEvent) is_invoice_payment_succeeded() bool {
	return event.event_type == 'invoice.payment_succeeded'
}

// is_invoice_payment_failed checks if this is an invoice payment failed event
pub fn (event StripeWebhookEvent) is_invoice_payment_failed() bool {
	return event.event_type == 'invoice.payment_failed'
}

// is_subscription_created checks if this is a subscription created event
pub fn (event StripeWebhookEvent) is_subscription_created() bool {
	return event.event_type == 'customer.subscription.created'
}

// is_subscription_updated checks if this is a subscription updated event
pub fn (event StripeWebhookEvent) is_subscription_updated() bool {
	return event.event_type == 'customer.subscription.updated'
}

// is_subscription_deleted checks if this is a subscription deleted event
pub fn (event StripeWebhookEvent) is_subscription_deleted() bool {
	return event.event_type == 'customer.subscription.deleted'
}

// is_test_event checks if this is a test mode event
pub fn (event StripeWebhookEvent) is_test_event() bool {
	return !event.livemode
}

// is_live_event checks if this is a live mode event
pub fn (event StripeWebhookEvent) is_live_event() bool {
	return event.livemode
}

// has_previous_attributes checks if the event has previous attributes (indicating an update)
pub fn (event StripeWebhookEvent) has_previous_attributes() bool {
	return event.data.previous_attributes != none
}

// get_event_category returns the category of the event (e.g., "payment_intent", "customer")
pub fn (event StripeWebhookEvent) get_event_category() string {
	parts := event.event_type.split('.')
	if parts.len > 0 {
		return parts[0]
	}
	return ''
}

// get_event_action returns the action of the event (e.g., "succeeded", "failed", "created")
pub fn (event StripeWebhookEvent) get_event_action() string {
	parts := event.event_type.split('.')
	if parts.len > 1 {
		return parts[parts.len - 1]
	}
	return ''
}
