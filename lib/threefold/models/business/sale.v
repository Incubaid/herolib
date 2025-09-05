module business

// SaleStatus represents the status of a sale
pub enum SaleStatus {
	pending   // Sale is pending
	completed // Sale has been completed
	cancelled // Sale was cancelled
}

// SaleItem represents an individual item within a Sale
pub struct SaleItem {
pub mut:
	product_id           u32    // Product ID
	name                 string // Denormalized product name at time of sale
	quantity             i32    // Quantity purchased
	unit_price           f64    // Price per unit at time of sale
	subtotal             f64    // Subtotal for this item
	service_active_until ?i64   // Optional: For services, date until this specific purchased instance is active
}

// new creates a new SaleItem with default values
pub fn SaleItem.new() SaleItem {
	return SaleItem{
		product_id:           0
		name:                 ''
		quantity:             0
		unit_price:           0.0
		subtotal:             0.0
		service_active_until: none
	}
}

// product_id sets the product ID (builder pattern)
pub fn (mut si SaleItem) product_id(product_id u32) SaleItem {
	si.product_id = product_id
	return si
}

// name sets the product name (builder pattern)
pub fn (mut si SaleItem) name(name string) SaleItem {
	si.name = name
	return si
}

// quantity sets the quantity (builder pattern)
pub fn (mut si SaleItem) quantity(quantity i32) SaleItem {
	si.quantity = quantity
	return si
}

// unit_price sets the unit price (builder pattern)
pub fn (mut si SaleItem) unit_price(unit_price f64) SaleItem {
	si.unit_price = unit_price
	return si
}

// subtotal sets the subtotal (builder pattern)
pub fn (mut si SaleItem) subtotal(subtotal f64) SaleItem {
	si.subtotal = subtotal
	return si
}

// service_active_until sets the service active until date (builder pattern)
pub fn (mut si SaleItem) service_active_until(service_active_until ?i64) SaleItem {
	si.service_active_until = service_active_until
	return si
}

// calculate_subtotal calculates and sets the subtotal based on quantity and unit price
pub fn (mut si SaleItem) calculate_subtotal() {
	si.subtotal = f64(si.quantity) * si.unit_price
}

// Sale represents a sale of products or services
@[heap]
pub struct Sale {
pub mut:
	id             u32        // Unique sale ID
	company_id     u32        // Company ID
	buyer_id       u32        // Buyer ID
	transaction_id u32        // Transaction ID
	total_amount   f64        // Total amount of the sale
	status         SaleStatus // Status of the sale
	sale_date      i64        // Sale date timestamp
	items          []SaleItem // Items in the sale
	notes          string     // Additional notes
	created_at     u64        // Creation timestamp
	updated_at     u64        // Last update timestamp
}

// new creates a new Sale with default values
pub fn Sale.new() Sale {
	return Sale{
		id:             0
		company_id:     0
		buyer_id:       0
		transaction_id: 0
		total_amount:   0.0
		status:         .pending
		sale_date:      0
		items:          []
		notes:          ''
		created_at:     0
		updated_at:     0
	}
}

// company_id sets the company ID (builder pattern)
pub fn (mut s Sale) company_id(company_id u32) Sale {
	s.company_id = company_id
	return s
}

// buyer_id sets the buyer ID (builder pattern)
pub fn (mut s Sale) buyer_id(buyer_id u32) Sale {
	s.buyer_id = buyer_id
	return s
}

// transaction_id sets the transaction ID (builder pattern)
pub fn (mut s Sale) transaction_id(transaction_id u32) Sale {
	s.transaction_id = transaction_id
	return s
}

// total_amount sets the total amount (builder pattern)
pub fn (mut s Sale) total_amount(total_amount f64) Sale {
	s.total_amount = total_amount
	return s
}

// status sets the status (builder pattern)
pub fn (mut s Sale) status(status SaleStatus) Sale {
	s.status = status
	return s
}

// sale_date sets the sale date (builder pattern)
pub fn (mut s Sale) sale_date(sale_date i64) Sale {
	s.sale_date = sale_date
	return s
}

// items sets all items (builder pattern)
pub fn (mut s Sale) items(items []SaleItem) Sale {
	s.items = items
	return s
}

// add_item adds an item to the sale (builder pattern)
pub fn (mut s Sale) add_item(item SaleItem) Sale {
	s.items << item
	return s
}

// notes sets the notes (builder pattern)
pub fn (mut s Sale) notes(notes string) Sale {
	s.notes = notes
	return s
}

// is_pending returns true if the sale is pending
pub fn (s Sale) is_pending() bool {
	return s.status == .pending
}

// is_completed returns true if the sale is completed
pub fn (s Sale) is_completed() bool {
	return s.status == .completed
}

// is_cancelled returns true if the sale is cancelled
pub fn (s Sale) is_cancelled() bool {
	return s.status == .cancelled
}

// complete completes the sale
pub fn (mut s Sale) complete() {
	s.status = .completed
}

// cancel cancels the sale
pub fn (mut s Sale) cancel() {
	s.status = .cancelled
}

// calculate_total calculates the total amount from all items
pub fn (mut s Sale) calculate_total() {
	mut total := 0.0
	for item in s.items {
		total += item.subtotal
	}
	s.total_amount = total
}

// get_item_by_product_id finds an item by product ID
pub fn (s Sale) get_item_by_product_id(product_id u32) ?SaleItem {
	for item in s.items {
		if item.product_id == product_id {
			return item
		}
	}
	return none
}

// total_items returns the total number of items
pub fn (s Sale) total_items() i32 {
	mut total := i32(0)
	for item in s.items {
		total += item.quantity
	}
	return total
}

// status_string returns the status as a string
pub fn (s Sale) status_string() string {
	return match s.status {
		.pending { 'Pending' }
		.completed { 'Completed' }
		.cancelled { 'Cancelled' }
	}
}
