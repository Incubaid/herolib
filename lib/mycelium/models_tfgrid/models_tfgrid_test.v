module models_tfgrid

fn test_bid_creation() {
	// Just a simple test to verify the module compiles
	bid := Bid{
		customer_id:    123
		requirements:   {
			'compute_nodes': '10'
		}
		pricing:        {
			'compute_nodes': '10.2'
		}
		status:         .pending
		obligation:     true
		start_date:     1234567890
		end_date:       1234567890
		signature_user: 'test_signature'
		billing_period: .monthly
	}

	assert bid.customer_id == 123
	assert bid.status == .pending
}

fn test_node_creation() {
	// Just a simple test to verify the module compiles
	node := Node{
		nodegroupid:      456
		country:          'US'
		uptime:           99
		pubkey:           'test_pubkey'
		signature_node:   'test_sig_node'
		signature_farmer: 'test_sig_farmer'
	}

	assert node.nodegroupid == 456
	assert node.country == 'US'
	assert node.uptime == 99
}
