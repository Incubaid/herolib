module geomind_poc

import crypto.rand
import time

// Commerce represents the main e-commerce server handling all operations
pub struct Commerce {
mut:
	merchants map[string]Merchant
	templates map[string]ProductTemplate
	products  map[string]Product
	orders    map[string]Order
}

// generate_id creates a unique identifier
fn generate_id() string {
	return rand.uuid_v4()
}

// create_merchant adds a new merchant to the system
pub fn (mut c Commerce) create_merchant(name string, description string, contact string) !Merchant {
	merchant_id := generate_id()
	merchant := Merchant{
		id:          merchant_id
		name:        name
		description: description
		contact:     contact
		active:      true
	}
	c.merchants[merchant_id] = merchant
	return merchant
}

// create_product_component_template creates a new component template
pub fn (mut c Commerce) create_product_component_template(name string, description string, specs map[string]string, price f64, currency string) !ProductComponentTemplate {
	component := ProductComponentTemplate{
		id:          generate_id()
		name:        name
		description: description
		specs:       specs
		price:       price
		currency:    currency
	}
	return component
}

// create_product_template creates a new product template
pub fn (mut c Commerce) create_product_template(name string, description string, components []ProductComponentTemplate, merchant_id string, category string) !ProductTemplate {
	if merchant_id !in c.merchants {
		return error('Merchant not found')
	}

	template := ProductTemplate{
		id:          generate_id()
		name:        name
		description: description
		components:  components
		merchant_id: merchant_id
		category:    category
		active:      true
	}
	c.templates[template.id] = template
	return template
}

// create_product creates a new product instance from a template
pub fn (mut c Commerce) create_product(template_id string, merchant_id string, stock_quantity int) !Product {
	if template_id !in c.templates {
		return error('Template not found')
	}
	if merchant_id !in c.merchants {
		return error('Merchant not found')
	}

	template := c.templates[template_id]
	mut total_price := 0.0
	for component in template.components {
		total_price += component.price
	}

	product := Product{
		id:             generate_id()
		template_id:    template_id
		name:           template.name
		description:    template.description
		price:          total_price
		currency:       template.components[0].currency // assuming all components use same currency
		merchant_id:    merchant_id
		stock_quantity: stock_quantity
		available:      true
	}
	c.products[product.id] = product
	return product
}

// create_order creates a new order
pub fn (mut c Commerce) create_order(customer_id string, items []OrderItem) !Order {
	mut total_amount := 0.0
	mut currency := ''

	for item in items {
		if item.product_id !in c.products {
			return error('Product not found: ${item.product_id}')
		}
		product := c.products[item.product_id]
		if !product.available || product.stock_quantity < item.quantity {
			return error('Product ${product.name} is not available in requested quantity')
		}
		total_amount += item.price * item.quantity
		if currency == '' {
			currency = item.currency
		} else if currency != item.currency {
			return error('Mixed currencies are not supported')
		}
	}

	order := Order{
		id:           generate_id()
		customer_id:  customer_id
		items:        items
		total_amount: total_amount
		currency:     currency
		status:       'pending'
		created_at:   time.now().str()
		updated_at:   time.now().str()
	}
	c.orders[order.id] = order

	// Update stock quantities
	for item in items {
		mut product := c.products[item.product_id]
		product.stock_quantity -= item.quantity
		if product.stock_quantity == 0 {
			product.available = false
		}
		c.products[item.product_id] = product
	}

	return order
}

// update_order_status updates the status of an order
pub fn (mut c Commerce) update_order_status(order_id string, new_status string) !Order {
	if order_id !in c.orders {
		return error('Order not found')
	}

	mut order := c.orders[order_id]
	order.status = new_status
	order.updated_at = time.now().str()
	c.orders[order_id] = order
	return order
}

// get_merchant_products returns all products for a given merchant
pub fn (c Commerce) get_merchant_products(merchant_id string) ![]Product {
	if merchant_id !in c.merchants {
		return error('Merchant not found')
	}

	mut products := []Product{}
	for product in c.products.values() {
		if product.merchant_id == merchant_id {
			products << product
		}
	}
	return products
}

// get_merchant_orders returns all orders for products sold by a merchant
pub fn (c Commerce) get_merchant_orders(merchant_id string) ![]Order {
	if merchant_id !in c.merchants {
		return error('Merchant not found')
	}

	mut orders := []Order{}
	for order in c.orders.values() {
		mut includes_merchant := false
		for item in order.items {
			product := c.products[item.product_id]
			if product.merchant_id == merchant_id {
				includes_merchant = true
				break
			}
		}
		if includes_merchant {
			orders << order
		}
	}
	return orders
}
