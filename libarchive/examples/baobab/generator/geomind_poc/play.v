module geomind_poc

import freeflowuniverse.crystallib.core.playbook { PlayBook }

// play_commerce processes heroscript actions for the commerce system
pub fn play_commerce(mut plbook PlayBook) ! {
	commerce_actions := plbook.find(filter: 'commerce.')!
	mut c := Commerce{}

	for action in commerce_actions {
		match action.name {
			'merchant' {
				mut p := action.params
				merchant := c.create_merchant(
					name:        p.get('name')!
					description: p.get_default('description', '')!
					contact:     p.get('contact')!
				)!
				println('Created merchant: ${merchant.name}')
			}
			'component' {
				mut p := action.params
				component := c.create_product_component_template(
					name:        p.get('name')!
					description: p.get_default('description', '')!
					specs:       p.get_map()
					price:       p.get_float('price')!
					currency:    p.get('currency')!
				)!
				println('Created component: ${component.name}')
			}
			'template' {
				mut p := action.params
				// Get component IDs as a list
				component_ids := p.get_list('components')!
				// Convert component IDs to actual components
				mut components := []ProductComponentTemplate{}
				for id in component_ids {
					// In a real implementation, you would fetch the component from storage
					// For this example, we create a dummy component
					component := ProductComponentTemplate{
						id:          id
						name:        'Component'
						description: ''
						specs:       map[string]string{}
						price:       0
						currency:    'USD'
					}
					components << component
				}

				template := c.create_product_template(
					name:        p.get('name')!
					description: p.get_default('description', '')!
					components:  components
					merchant_id: p.get('merchant_id')!
					category:    p.get_default('category', 'General')!
				)!
				println('Created template: ${template.name}')
			}
			'product' {
				mut p := action.params
				product := c.create_product(
					template_id:    p.get('template_id')!
					merchant_id:    p.get('merchant_id')!
					stock_quantity: p.get_int('stock_quantity')!
				)!
				println('Created product: ${product.name} with stock: ${product.stock_quantity}')
			}
			'order' {
				mut p := action.params
				// Get order items as a list of maps
				items_data := p.get_list('items')!
				mut items := []OrderItem{}
				for item_data in items_data {
					// Parse item data (format: "product_id:quantity:price:currency")
					parts := item_data.split(':')
					if parts.len != 4 {
						return error('Invalid order item format: ${item_data}')
					}
					item := OrderItem{
						product_id: parts[0]
						quantity:   parts[1].int()
						price:      parts[2].f64()
						currency:   parts[3]
					}
					items << item
				}

				order := c.create_order(
					customer_id: p.get('customer_id')!
					items:       items
				)!
				println('Created order: ${order.id} with ${order.items.len} items')
			}
			'update_order' {
				mut p := action.params
				order := c.update_order_status(
					order_id:   p.get('order_id')!
					new_status: p.get('status')!
				)!
				println('Updated order ${order.id} status to: ${order.status}')
			}
			else {
				return error('Unknown commerce action: ${action.name}')
			}
		}
	}
}

// Example heroscript usage:
/*
!!commerce.merchant
    name: "Tech Gadgets Store"
    description: "Premium electronics and gadgets retailer"
    contact: "contact@techgadgets.com"

!!commerce.component
    name: "4K Display Panel"
    description: "55-inch 4K UHD Display Panel"
    specs:
        resolution: "3840x2160"
        refreshRate: "120Hz"
        panel_type: "OLED"
    price: 599.99
    currency: "USD"

!!commerce.template
    name: "Smart TV 55-inch"
    description: "55-inch Smart TV with 4K Display"
    components: "123e4567-e89b-12d3-a456-426614174001"
    merchant_id: "123e4567-e89b-12d3-a456-426614174000"
    category: "Electronics"

!!commerce.product
    template_id: "123e4567-e89b-12d3-a456-426614174002"
    merchant_id: "123e4567-e89b-12d3-a456-426614174000"
    stock_quantity: 50

!!commerce.order
    customer_id: "123e4567-e89b-12d3-a456-426614174005"
    items:
        - "123e4567-e89b-12d3-a456-426614174003:2:899.99:USD"

!!commerce.update_order
    order_id: "123e4567-e89b-12d3-a456-426614174004"
    status: "shipped"
*/
