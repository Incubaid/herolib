module geomind_poc

pub struct Merchant {
pub:
	id          string
	name        string
	description string
	contact     string
	active      bool
}

pub struct ProductComponentTemplate {
pub:
	id          string
	name        string
	description string
	// technical specifications
	specs map[string]string
	// price per unit
	price f64
	// currency code (e.g., 'USD', 'EUR')
	currency string
}

pub struct ProductTemplate {
pub:
	id          string
	name        string
	description string
	// components that make up this product template
	components []ProductComponentTemplate
	// merchant who created this template
	merchant_id string
	// category of the product (e.g., 'electronics', 'clothing')
	category string
	// whether this template is available for use
	active bool
}

pub struct Product {
pub:
	id          string
	template_id string
	// specific instance details that may differ from template
	name        string
	description string
	// actual price of this product instance
	price    f64
	currency string
	// merchant selling this product
	merchant_id string
	// current stock level
	stock_quantity int
	// whether this product is available for purchase
	available bool
}

pub struct OrderItem {
pub:
	product_id string
	quantity   int
	price      f64
	currency   string
}

pub struct Order {
pub:
	id string
	// customer identifier
	customer_id string
	// items in the order
	items []OrderItem
	// total order amount
	total_amount f64
	currency     string
	// order status (e.g., 'pending', 'confirmed', 'shipped', 'delivered')
	status string
	// timestamps
	created_at string
	updated_at string
}
