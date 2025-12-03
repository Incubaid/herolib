#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

// This example tests the filter to_map() functionality
// to ensure Option types are properly serialized for API query parameters.

import incubaid.herolib.mycelium.grid3.gridproxy
import incubaid.herolib.mycelium.grid3.gridproxy.model
import incubaid.herolib.ui.console

fn test_node_filter_to_map() {
	console.print_header('Testing NodeFilter.to_map()')

	mut filter := model.NodeFilter{}
	filter.status = 'up'
	filter.country = 'Belgium'
	filter.total_cru = u64(2)
	filter.healthy = true
	filter.free_ips = u64(1)

	m := filter.to_map()

	console.print_debug('Filter map: ${m}')

	// Verify the values are correctly serialized (not "Option(...)")
	assert m['status'] == 'up', 'status should be "up", got "${m['status']}"'
	assert m['country'] == 'Belgium', 'country should be "Belgium", got "${m['country']}"'
	assert m['total_cru'] == '2', 'total_cru should be "2", got "${m['total_cru']}"'
	assert m['healthy'] == 'true', 'healthy should be "true", got "${m['healthy']}"'
	assert m['free_ips'] == '1', 'free_ips should be "1", got "${m['free_ips']}"'

	// Verify that unset optional fields are NOT in the map
	assert 'city' !in m, 'city should not be in map when not set'
	assert 'farm_name' !in m, 'farm_name should not be in map when not set'

	console.print_green('✓ NodeFilter.to_map() test passed!')
}

fn test_farm_filter_to_map() {
	console.print_header('Testing FarmFilter.to_map()')

	mut filter := model.FarmFilter{}
	filter.country = 'Egypt'
	filter.total_ips = u64(10)
	filter.dedicated = false

	m := filter.to_map()

	console.print_debug('Filter map: ${m}')

	assert m['country'] == 'Egypt', 'country should be "Egypt", got "${m['country']}"'
	assert m['total_ips'] == '10', 'total_ips should be "10", got "${m['total_ips']}"'
	assert m['dedicated'] == 'false', 'dedicated should be "false", got "${m['dedicated']}"'

	console.print_green('✓ FarmFilter.to_map() test passed!')
}

fn test_contract_filter_to_map() {
	console.print_header('Testing ContractFilter.to_map()')

	mut filter := model.ContractFilter{}
	filter.twin_id = u64(123)
	filter.state = 'Created'
	filter.contract_type = 'node'

	m := filter.to_map()

	console.print_debug('Filter map: ${m}')

	assert m['twin_id'] == '123', 'twin_id should be "123", got "${m['twin_id']}"'
	assert m['state'] == 'Created', 'state should be "Created", got "${m['state']}"'
	assert m['contract_type'] == 'node', 'contract_type should be "node", got "${m['contract_type']}"'

	console.print_green('✓ ContractFilter.to_map() test passed!')
}

fn test_twin_filter_to_map() {
	console.print_header('Testing TwinFilter.to_map()')

	mut filter := model.TwinFilter{}
	filter.twin_id = u64(456)
	filter.page = u64(1)
	filter.size = u64(50)

	m := filter.to_map()

	console.print_debug('Filter map: ${m}')

	assert m['twin_id'] == '456', 'twin_id should be "456", got "${m['twin_id']}"'
	assert m['page'] == '1', 'page should be "1", got "${m['page']}"'
	assert m['size'] == '50', 'size should be "50", got "${m['size']}"'

	console.print_green('✓ TwinFilter.to_map() test passed!')
}

fn test_api_call_with_filter() ! {
	console.print_header('Testing actual API call with filter')

	mut filter := model.NodeFilter{}
	filter.status = 'up'
	filter.size = u64(5) // Limit results

	console.print_debug('Making API call with filter: ${filter.to_map()}')

	mut gp_client := gridproxy.new(net: .main, cache: false)!
	nodes := gp_client.get_nodes(filter)!

	console.print_debug('Got ${nodes.len} nodes')
	assert nodes.len > 0, 'Should get at least one node'
	assert nodes.len <= 5, 'Should get at most 5 nodes (size limit)'

	// Verify all returned nodes are "up"
	for node in nodes {
		assert node.status == 'up', 'All nodes should have status "up"'
	}

	console.print_green('✓ API call with filter test passed!')
}

fn main() {
	console.print_header('=== Grid Proxy Filter Tests ===')

	// Test to_map serialization
	test_node_filter_to_map()
	test_farm_filter_to_map()
	test_contract_filter_to_map()
	test_twin_filter_to_map()

	// Test actual API call
	test_api_call_with_filter()!

	console.print_header('=== All tests passed! ===')
}

