module business

// ProductType represents the type of a product
pub enum ProductType {
	product // Physical or digital product
	service // Service offering
}

// ProductStatus represents the status of a product
pub enum ProductStatus {
	available   // Product is available for purchase
	unavailable // Product is not available
}

// ProductComponent represents a component or sub-part of a product
pub struct ProductComponent {
pub mut:
	name        string // Component name
	description string // Component description
	quantity    u32    // Quantity of this component
}

// new creates a new ProductComponent with default values
pub fn ProductComponent.new() ProductComponent {
	return ProductComponent{
		name: ''
		description: ''
		quantity: 1
	}
}

// name sets the component name (builder pattern)
pub fn (mut pc ProductComponent) name(name string) ProductComponent {
	pc.name = name
	return pc
}

// description sets the component description (builder pattern)
pub fn (mut pc ProductComponent) description(description string) ProductComponent {
	pc.description = description
	return pc
}

// quantity sets the component quantity (builder pattern)
pub fn (mut pc ProductComponent) quantity(quantity u32) ProductComponent {
	pc.quantity = quantity
	return pc
}

// Product represents a product or service offered
@[heap]
pub struct Product {
pub mut:
	id            u32                 // Unique product ID
	name          string              // Product name
	description   string              // Product description
	price         f64                 // Product price
	type_         ProductType         // Product type (product or service)
	category      string              // Product category
	status        ProductStatus       // Product status
	max_amount    u16                 // Maximum amount available
	purchase_till i64                 // Purchase deadline timestamp
	active_till   i64                 // Active until timestamp
	components    []ProductComponent  // Product components
	created_at    u64                 // Creation timestamp
	updated_at    u64                 // Last update timestamp
}

// new creates a new Product with default values
pub fn Product.new() Product {
	return Product{
		id: 0
		name: ''
		description: ''
		price: 0.0
		type_: .product
		category: ''
		status: .available
		max_amount: 0
		purchase_till: 0
		active_till: 0
		components: []
		created_at: 0
		updated_at: 0
	}
}

// name sets the product name (builder pattern)
pub fn (mut p Product) name(name string) Product {
	p.name = name
	return p
}

// description sets the product description (builder pattern)
pub fn (mut p Product) description(description string) Product {
	p.description = description
	return p
}

// price sets the product price (builder pattern)
pub fn (mut p Product) price(price f64) Product {
	p.price = price
	return p
}

// type_ sets the product type (builder pattern)
pub fn (mut p Product) type_(type_ ProductType) Product {
	p.type_ = type_
	return p
}

// category sets the product category (builder pattern)
pub fn (mut p Product) category(category string) Product {
	p.category = category
	return p
}

// status sets the product status (builder pattern)
pub fn (mut p Product) status(status ProductStatus) Product {
	p.status = status
	return p
}

// max_amount sets the maximum amount (builder pattern)
pub fn (mut p Product) max_amount(max_amount u16) Product {
	p.max_amount = max_amount
	return p
}

// purchase_till sets the purchase deadline (builder pattern)
pub fn (mut p Product) purchase_till(purchase_till i64) Product {
	p.purchase_till = purchase_till
	return p
}

// active_till sets the active until timestamp (builder pattern)
pub fn (mut p Product) active_till(active_till i64) Product {
	p.active_till = active_till
	return p
}

// add_component adds a component to the product (builder pattern)
pub fn (mut p Product) add_component(component ProductComponent) Product {
	p.components << component
	return p
}

// components sets all components (builder pattern)
pub fn (mut p Product) components(components []ProductComponent) Product {
	p.components = components
	return p
}

// is_available returns true if the product is available
pub fn (p Product) is_available() bool {
	return p.status == .available
}

// is_service returns true if the product is a service
pub fn (p Product) is_service() bool {
	return p.type_ == .service
}

// is_product returns true if the product is a physical/digital product
pub fn (p Product) is_product() bool {
	return p.type_ == .product
}

// make_available makes the product available
pub fn (mut p Product) make_available() {
	p.status = .available
}

// make_unavailable makes the product unavailable
pub fn (mut p Product) make_unavailable() {
	p.status = .unavailable
}

// get_component_by_name finds a component by name
pub fn (p Product) get_component_by_name(name string) ?ProductComponent {
	for component in p.components {
		if component.name == name {
			return component
		}
	}
	return none
}

// total_components returns the total number of components
pub fn (p Product) total_components() u32 {
	mut total := u32(0)
	for component in p.components {
		total += component.quantity
	}
	return total
}

// type_string returns the product type as a string
pub fn (p Product) type_string() string {
	return match p.type_ {
		.product { 'Product' }
		.service { 'Service' }
	}
}

// status_string returns the product status as a string
pub fn (p Product) status_string() string {
	return match p.status {
		.available { 'Available' }
		.unavailable { 'Unavailable' }
	}
}