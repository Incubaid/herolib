module model

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
	mut m := map[string]string{}
	if v := f.page { m['page'] = v.str() }
	if v := f.size { m['size'] = v.str() }
	if v := f.ret_count { m['ret_count'] = v.str() }
	if v := f.randomize { m['randomize'] = v.str() }
	if v := f.free_ips { m['free_ips'] = v.str() }
	if v := f.total_ips { m['total_ips'] = v.str() }
	if v := f.stellar_address { m['stellar_address'] = v }
	if v := f.pricing_policy_id { m['pricing_policy_id'] = v.str() }
	if v := f.farm_id { m['farm_id'] = v.str() }
	if v := f.twin_id { m['twin_id'] = v.str() }
	if v := f.name { m['name'] = v }
	if v := f.name_contains { m['name_contains'] = v }
	if v := f.certification_type { m['certification_type'] = v }
	if v := f.dedicated { m['dedicated'] = v.str() }
	if v := f.country { m['country'] = v }
	if v := f.node_free_mru { m['node_free_mru'] = v.str() }
	if v := f.node_free_hru { m['node_free_hru'] = v.str() }
	if v := f.node_free_sru { m['node_free_sru'] = v.str() }
	if v := f.node_status { m['node_status'] = v }
	if v := f.node_rented_by { m['node_rented_by'] = v.str() }
	if v := f.node_available_for { m['node_available_for'] = v.str() }
	if v := f.node_has_gpu { m['node_has_gpu'] = v.str() }
	if v := f.node_certified { m['node_certified'] = v.str() }
	return m
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
	mut m := map[string]string{}
	if v := f.page { m['page'] = v.str() }
	if v := f.size { m['size'] = v.str() }
	if v := f.ret_count { m['ret_count'] = v.str() }
	if v := f.randomize { m['randomize'] = v.str() }
	if v := f.contract_id { m['contract_id'] = v.str() }
	if v := f.twin_id { m['twin_id'] = v.str() }
	if v := f.node_id { m['node_id'] = v.str() }
	if v := f.contract_type { m['contract_type'] = v }
	if v := f.state { m['state'] = v }
	if v := f.name { m['name'] = v }
	if v := f.number_of_public_ips { m['number_of_public_ips'] = v.str() }
	if v := f.deployment_data { m['deployment_data'] = v }
	if v := f.deployment_hash { m['deployment_hash'] = v }
	return m
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
	mut m := map[string]string{}
	
	// Handle optional u64 fields
	if v := f.page { m['page'] = v.str() }
	if v := f.size { m['size'] = v.str() }
	if v := f.free_mru { m['free_mru'] = v.str() }
	if v := f.free_sru { m['free_sru'] = v.str() }
	if v := f.free_hru { m['free_hru'] = v.str() }
	if v := f.free_ips { m['free_ips'] = v.str() }
	if v := f.total_mru { m['total_mru'] = v.str() }
	if v := f.total_sru { m['total_sru'] = v.str() }
	if v := f.total_hru { m['total_hru'] = v.str() }
	if v := f.total_cru { m['total_cru'] = v.str() }
	if v := f.rented_by { m['rented_by'] = v.str() }
	if v := f.available_for { m['available_for'] = v.str() }
	if v := f.node_id { m['node_id'] = v.str() }
	if v := f.twin_id { m['twin_id'] = v.str() }
	
	// Handle optional bool fields
	if v := f.ret_count { m['ret_count'] = v.str() }
	if v := f.randomize { m['randomize'] = v.str() }
	if v := f.ipv4 { m['ipv4'] = v.str() }
	if v := f.ipv6 { m['ipv6'] = v.str() }
	if v := f.domain { m['domain'] = v.str() }
	if v := f.dedicated { m['dedicated'] = v.str() }
	if v := f.healthy { m['healthy'] = v.str() }
	if v := f.rentable { m['rentable'] = v.str() }
	if v := f.rented { m['rented'] = v.str() }
	if v := f.has_gpu { m['has_gpu'] = v.str() }
	if v := f.has_ipv6 { m['has_ipv6'] = v.str() }
	if v := f.gpu_available { m['gpu_available'] = v.str() }
	
	// Handle optional string fields
	if v := f.city { m['city'] = v }
	if v := f.city_contains { m['city_contains'] = v }
	if v := f.country { m['country'] = v }
	if v := f.country_contains { m['country_contains'] = v }
	if v := f.farm_name { m['farm_name'] = v }
	if v := f.farm_name_contains { m['farm_name_contains'] = v }
	if v := f.status { m['status'] = v }
	if v := f.certification_type { m['certification_type'] = v }
	if v := f.gpu_device_id { m['gpu_device_id'] = v }
	if v := f.gpu_device_name { m['gpu_device_name'] = v }
	if v := f.gpu_vendor_id { m['gpu_vendor_id'] = v }
	if v := f.gpu_vendor_name { m['gpu_vendor_name'] = v }
	
	// Handle array fields
	if f.farm_ids.len > 0 { m['farm_ids'] = f.farm_ids.map(it.str()).join(',') }
	if f.node_ids.len > 0 { m['node_ids'] = f.node_ids.map(it.str()).join(',') }
	if f.features.len > 0 { m['features'] = f.features.join(',') }
	
	return m
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
	mut m := map[string]string{}
	if v := f.page { m['page'] = v.str() }
	if v := f.size { m['size'] = v.str() }
	if v := f.ret_count { m['ret_count'] = v.str() }
	if v := f.randomize { m['randomize'] = v.str() }
	if v := f.twin_id { m['twin_id'] = v.str() }
	if v := f.account_id { m['account_id'] = v }
	if v := f.relay { m['relay'] = v }
	if v := f.public_key { m['public_key'] = v }
	return m
}
