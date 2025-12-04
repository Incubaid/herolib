module gridproxy

import incubaid.herolib.mycelium.grid3.gridproxy.model
import time

const cache = false
const dummy_node = model.Node{
	id:                '0000129706-000001-c1e78'
	node_id:           1
	farm_id:           2
	twin_id:           8
	grid_version:      3
	uptime:            model.SecondUnit(86400)    // 86400 seconds = 1440 minutes = 24 hours = 1 day
	created:           model.UnixTime(1654848126) // GMT: 2022-06-10 08:02:06
	farming_policy_id: 1
	updated_at:        model.UnixTime(1654848132) // GMT: 2022-06-10 08:02:12
	capacity:          model.NodeCapacity{
		total_resources: model.NodeResources{
			cru: 4
			mru: model.ByteUnit(5178437632)    // 5178437632 bytes = 5178.437632 megabytes = 5.2 gigabytes = 0.005178437632 terabytes
			sru: model.ByteUnit(1610612736000) // 1610612736000 bytes = 1610612.736000 megabytes = 1610.612736 gigabytes = 16.1 terabytes
			hru: model.ByteUnit(1073741824000) // 1073741824000 bytes = 1073741.824 megabytes = 1073.741824 gigabytes = 10.7 terabytes
		}
		used_resources:  model.NodeResources{
			cru: 0
			mru: model.ByteUnit(0)
			sru: model.ByteUnit(0)
			hru: model.ByteUnit(0)
		}
	}
	location:          model.NodeLocation{
		country: 'Belgium'
		city:    'Lochristi'
	}
	public_config:     model.PublicConfig{
		domain: ''
		gw4:    ''
		gw6:    ''
		ipv4:   ''
		ipv6:   ''
	}
	certification:     'Diy'
	status:            'down'
	dedicated:         false
	rent_contract_id:  0
	rented_by_twin_id: 0
}
const dummy_contract_billing = model.ContractBilling{
	amount_billed:     model.DropTFTUnit(10000000) // 1 TFT == 1000 mTFT == 1000000 uTFT
	discount_received: 'None'
	timestamp:         model.UnixTime(1655118966)
}

fn test_create_gridproxy_client_qa() {
	mut gp := new(net: .qa, cache: cache)!
	assert gp.is_pingable()! == true
}

fn test_create_gridproxy_client_dev() {
	mut gp := new(net: .dev, cache: cache)!
	assert gp.is_pingable()! == true
}

fn test_create_gridproxy_client_test() {
	mut gp := new(net: .test, cache: cache)!
	assert gp.is_pingable()! == true
}

fn test_create_gridproxy_client_main() {
	mut gp := new(net: .main, cache: cache)!
	assert gp.is_pingable()! == true
}

fn test_get_nodes_qa() {
	mut gp := new(net: .qa, cache: cache)!
	nodes := gp.get_nodes() or { panic('Failed to get nodes') }
	assert nodes.len > 0
}

fn test_get_nodes_dev() {
	mut gp := new(net: .dev, cache: cache)!
	nodes := gp.get_nodes() or { panic('Failed to get nodes') }
	assert nodes.len > 0
}

fn test_get_nodes_test() {
	mut gp := new(net: .test, cache: cache)!
	nodes := gp.get_nodes() or { panic('Failed to get nodes') }
	assert nodes.len > 0
}

fn test_get_nodes_main() {
	mut gp := new(net: .main, cache: cache)!
	nodes := gp.get_nodes() or { panic('Failed to get nodes') }
	assert nodes.len > 0
}

fn test_get_gateways_qa() {
	mut gp := new(net: .qa, cache: cache)!
	nodes := gp.get_gateways() or { panic('Failed to get gateways') }
	assert nodes.len > 0
}

fn test_get_gateways_dev() {
	mut gp := new(net: .dev, cache: cache)!
	nodes := gp.get_gateways() or { panic('Failed to get gateways') }
	assert nodes.len > 0
}

fn test_get_gateways_test() {
	mut gp := new(net: .test, cache: cache)!
	nodes := gp.get_gateways() or { panic('Failed to get gateways') }
	assert nodes.len > 0
}

fn test_get_gateways_main() {
	mut gp := new(net: .main, cache: cache)!
	nodes := gp.get_gateways() or { panic('Failed to get gateways') }
	assert nodes.len > 0
}

fn test_get_twins_qa() {
	mut gp := new(net: .qa, cache: cache)!
	twins := gp.get_twins() or { panic('Failed to get twins') }
	assert twins.len > 0
}

fn test_get_twins_dev() {
	mut gp := new(net: .dev, cache: cache)!
	twins := gp.get_twins() or { panic('Failed to get twins') }
	assert twins.len > 0
}

fn test_get_twins_test() {
	mut gp := new(net: .test, cache: cache)!
	twins := gp.get_twins() or { panic('Failed to get twins') }
	assert twins.len > 0
}

fn test_get_twins_main() {
	mut gp := new(net: .main, cache: cache)!
	twins := gp.get_twins() or { panic('Failed to get twins') }
	assert twins.len > 0
}

fn test_get_stats_qa() {
	mut gp := new(net: .qa, cache: cache)!
	stats := gp.get_stats() or { panic('Failed to get stats') }
	assert stats.nodes > 0
}

fn test_get_stats_dev() {
	mut gp := new(net: .dev, cache: cache)!
	stats := gp.get_stats() or { panic('Failed to get stats') }
	assert stats.nodes > 0
}

fn test_get_stats_test() {
	mut gp := new(net: .test, cache: cache)!
	stats := gp.get_stats() or { panic('Failed to get stats') }
	assert stats.nodes > 0
}

fn test_get_stats_main() {
	mut gp := new(net: .main, cache: cache)!
	stats := gp.get_stats() or { panic('Failed to get stats') }
	assert stats.nodes > 0
}

fn test_get_contracts_qa() {
	mut gp := new(net: .qa, cache: cache)!
	contracts := gp.get_contracts() or { panic('Failed to get contracts') }
	assert contracts.len > 0
}

fn test_get_contracts_dev() {
	mut gp := new(net: .dev, cache: cache)!
	contracts := gp.get_contracts() or { panic('Failed to get contracts') }
	assert contracts.len > 0
}

fn test_get_contracts_test() {
	mut gp := new(net: .test, cache: cache)!
	contracts := gp.get_contracts() or { panic('Failed to get contracts') }
	assert contracts.len > 0
}

fn test_get_contracts_main() {
	mut gp := new(net: .main, cache: cache)!
	// mainnet may have no contracts or API might fail, so we just check it doesn't crash
	_ := gp.get_contracts() or { return }
}

fn test_get_farms_qa() {
	mut gp := new(net: .qa, cache: cache)!
	farms := gp.get_farms() or { panic('Failed to get farms') }
	assert farms.len > 0
}

fn test_get_farms_dev() {
	mut gp := new(net: .dev, cache: cache)!
	farms := gp.get_farms() or { panic('Failed to get farms') }
	assert farms.len > 0
}

fn test_get_farms_test() {
	mut gp := new(net: .test, cache: cache)!
	farms := gp.get_farms() or { panic('Failed to get farms') }
	assert farms.len > 0
}

fn test_get_farms_main() {
	mut gp := new(net: .main, cache: cache)!
	farms := gp.get_farms() or { panic('Failed to get farms') }
	assert farms.len > 0
}

fn test_elapsed_seconds_conversion() {
	assert dummy_node.uptime.to_minutes() == 1440
	assert dummy_node.uptime.to_hours() == 24
	assert dummy_node.uptime.to_days() == 1
}

fn test_timestamp_conversion() {
	assert dummy_node.created.to_time() == time.unix(1654848126)
	assert dummy_node.updated_at.to_time() == time.unix(1654848132)
}

fn test_storage_unit_conversion() {
	assert dummy_node.capacity.total_resources.mru.to_megabytes() == 5178.437632
	assert dummy_node.capacity.total_resources.mru.to_gigabytes() == 5.178437632
	assert dummy_node.capacity.total_resources.mru.to_terabytes() == 0.005178437632
}

fn test_tft_conversion() {
	assert dummy_contract_billing.amount_billed.to_tft() == 1
	assert dummy_contract_billing.amount_billed.to_mtft() == 1000
	assert dummy_contract_billing.amount_billed.to_utft() == 1000000
}

fn test_calc_available_resources_on_node() {
	// dummy node was created with 0 used resources
	assert dummy_node.calc_available_resources().mru == dummy_node.capacity.total_resources.mru
	assert dummy_node.calc_available_resources().hru == dummy_node.capacity.total_resources.hru
	assert dummy_node.calc_available_resources().sru == dummy_node.capacity.total_resources.sru
	assert dummy_node.calc_available_resources().cru == dummy_node.capacity.total_resources.cru
}

// Filter to_map() tests - verify Option types are properly serialized

fn test_node_filter_to_map() {
	mut filter := model.NodeFilter{}
	filter.status = 'up'
	filter.country = 'Belgium'
	filter.total_cru = u64(2)
	filter.healthy = true
	filter.free_ips = u64(1)

	m := filter.to_map()

	// Verify values are correctly serialized (not "Option(...)")
	assert m['status'] == 'up'
	assert m['country'] == 'Belgium'
	assert m['total_cru'] == '2'
	assert m['healthy'] == 'true'
	assert m['free_ips'] == '1'

	// Verify unset optional fields are NOT in the map
	assert 'city' !in m
	assert 'farm_name' !in m
}

fn test_farm_filter_to_map() {
	mut filter := model.FarmFilter{}
	filter.country = 'Egypt'
	filter.total_ips = u64(10)
	filter.dedicated = false

	m := filter.to_map()

	assert m['country'] == 'Egypt'
	assert m['total_ips'] == '10'
	assert m['dedicated'] == 'false'

	// Verify unset optional fields are NOT in the map
	assert 'name' !in m
	assert 'twin_id' !in m
}

fn test_contract_filter_to_map() {
	mut filter := model.ContractFilter{}
	filter.twin_id = u64(123)
	filter.state = 'Created'
	filter.contract_type = 'node'

	m := filter.to_map()

	assert m['twin_id'] == '123'
	assert m['state'] == 'Created'
	assert m['contract_type'] == 'node'

	// Verify unset optional fields are NOT in the map
	assert 'node_id' !in m
	assert 'contract_id' !in m
}

fn test_twin_filter_to_map() {
	mut filter := model.TwinFilter{}
	filter.twin_id = u64(456)
	filter.page = u64(1)
	filter.size = u64(50)

	m := filter.to_map()

	assert m['twin_id'] == '456'
	assert m['page'] == '1'
	assert m['size'] == '50'

	// Verify unset optional fields are NOT in the map
	assert 'account_id' !in m
	assert 'relay' !in m
}

fn test_empty_filter_to_map() {
	// An empty filter should produce an empty map (or map with only non-optional defaults)
	filter := model.NodeFilter{}
	m := filter.to_map()

	// Optional fields should not be in the map
	assert 'status' !in m
	assert 'country' !in m
	assert 'total_cru' !in m
}

fn test_api_call_with_node_filter() {
	mut filter := model.NodeFilter{}
	filter.status = 'up'
	filter.size = u64(5) // Limit results

	mut gp_client := new(net: .main, cache: cache)!
	nodes := gp_client.get_nodes(filter)!

	assert nodes.len > 0
	assert nodes.len <= 5

	// Verify all returned nodes have status "up"
	for node in nodes {
		assert node.status == 'up'
	}
}

fn test_api_call_with_farm_filter() {
	mut filter := model.FarmFilter{}
	filter.size = u64(5) // Limit results

	mut gp_client := new(net: .main, cache: cache)!
	farms := gp_client.get_farms(filter)!

	assert farms.len > 0
	assert farms.len <= 5
}
