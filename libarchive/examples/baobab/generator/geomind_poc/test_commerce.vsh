#!/usr/bin/env -S v

import freeflowuniverse.crystallib.core.playbook
import geomind_poc

fn main() {
	test_script := "
!!commerce.merchant
    name: 'Tech Gadgets Store'
    description: 'Premium electronics and gadgets retailer'
    contact: 'contact@techgadgets.com'

!!commerce.component
    name: '4K Display Panel'
    description: '55-inch 4K UHD Display Panel'
    specs:
        resolution: '3840x2160'
        refreshRate: '120Hz'
        panel_type: 'OLED'
    price: 599.99
    currency: 'USD'

!!commerce.template
    name: 'Smart TV 55-inch'
    description: '55-inch Smart TV with 4K Display'
    components: '123e4567-e89b-12d3-a456-426614174001'
    merchant_id: '123e4567-e89b-12d3-a456-426614174000'
    category: 'Electronics'

!!commerce.product
    template_id: '123e4567-e89b-12d3-a456-426614174002'
    merchant_id: '123e4567-e89b-12d3-a456-426614174000'
    stock_quantity: 50

!!commerce.order
    customer_id: '123e4567-e89b-12d3-a456-426614174005'
    items:
        - '123e4567-e89b-12d3-a456-426614174003:2:899.99:USD'

!!commerce.update_order
    order_id: '123e4567-e89b-12d3-a456-426614174004'
    status: 'shipped'
"

	mut plbook := playbook.new(text: test_script)!
	geomind_poc.play_commerce(mut plbook)!
}
