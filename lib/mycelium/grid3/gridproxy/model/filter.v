module model

import x.json2

@[params]
pub struct FarmFilter {
pub mut:
	page               ?u64
	size               ?u64
	ret_count          ?bool
	randomize          ?bool
	free_ips           ?u64
	total_ips          ?u64
	stellar_address    ?string
	pricing_policy_id  ?u64
	farm_id            ?u64
	twin_id            ?u64
	name               ?string
	name_contains      ?string
	certification_type ?string
	dedicated          ?bool
	country            ?string
	node_free_mru      ?u64
	node_free_hru      ?u64
	node_free_sru      ?u64
	node_status        ?string
	node_rented_by     ?u64
	node_available_for ?u64
	node_has_gpu       ?bool
	node_certified     ?bool
}

// serialize FarmFilter to map
pub fn (f FarmFilter) to_map() map[string]string {
	return to_map(f)
}

@[params]
pub struct ContractFilter {
pub mut:
	page                 ?u64
	size                 ?u64
	ret_count            ?bool
	randomize            ?bool
	contract_id          ?u64
	twin_id              ?u64
	node_id              ?u64
	contract_type        ?string
	state                ?string
	name                 ?string
	number_of_public_ips ?u64
	deployment_data      ?string
	deployment_hash      ?string
}

// serialize ContractFilter to map
pub fn (f ContractFilter) to_map() map[string]string {
	return to_map(f)
}

@[params]
pub struct NodeFilter {
pub mut:
	page               ?u64
	size               ?u64
	ret_count          ?bool
	randomize          ?bool
	free_mru           ?u64
	free_sru           ?u64
	free_hru           ?u64
	free_ips           ?u64
	total_mru          ?u64
	total_sru          ?u64
	total_hru          ?u64
	total_cru          ?u64
	city               ?string
	city_contains      ?string
	country            ?string
	country_contains   ?string
	farm_name          ?string
	farm_name_contains ?string
	ipv4               ?bool
	ipv6               ?bool
	domain             ?bool
	status             ?string
	dedicated          ?bool
	healthy            ?bool
	rentable           ?bool
	rented_by          ?u64
	rented             ?bool
	available_for      ?u64
	farm_ids           []u64
	node_ids           []u64
	node_id            ?u32
	twin_id            ?u64
	certification_type ?string
	has_gpu            ?bool
	has_ipv6           ?bool
	gpu_device_id      ?string
	gpu_device_name    ?string
	gpu_vendor_id      ?string
	gpu_vendor_name    ?string
	gpu_available      ?bool
	features           []string
}

// serialize NodeFilter to map
pub fn (f NodeFilter) to_map() map[string]string {
	return to_map(f)
}

pub enum NodeStatus {
	all
	online
}

@[params]
pub struct ResourceFilter {
pub mut:
	free_mru_gb u64
	free_sru_gb u64
	free_hru_gb u64
	free_cpu    u64
	free_ips    u64
}

@[params]
pub struct StatFilter {
pub mut:
	status NodeStatus
}

@[params]
pub struct TwinFilter {
pub mut:
	page       ?u64
	size       ?u64
	ret_count  ?bool
	randomize  ?bool
	twin_id    ?u64
	account_id ?string
	relay      ?string
	public_key ?string
}

// serialize TwinFilter to map
pub fn (f TwinFilter) to_map() map[string]string {
	return to_map(f)
}

// to_map converts any struct to map[string]string using JSON as intermediary.
// This properly handles Option types by leveraging V's built-in JSON encoder
// which correctly serializes ?T as either the value or null.
pub fn to_map[T](t T) map[string]string {
	mut m := map[string]string{}

	// Use JSON encoding which properly handles Option types
	encoded := json2.encode(t)
	json_map := json2.decode[json2.Any](encoded) or { return m }.as_map()

	for key, val in json_map {
		match val {
			json2.Null {
				// Skip null/none values - don't include in query params
				continue
			}
			[]json2.Any {
				// Handle arrays: join elements with comma
				if val.len > 0 {
					m[key] = val.map(it.str().trim('"')).join(',')
				}
			}
			else {
				// Handle all other types: convert to string, trim quotes from strings
				str_val := val.str().trim('"')
				if str_val.len > 0 {
					m[key] = str_val
				}
			}
		}
	}
	return m
}
