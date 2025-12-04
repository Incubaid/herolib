module datamodel

// is a root object, is the only obj farmer needs to configure in the UI, this defines how slices will be created
@[heap]
pub struct NodeGroup {
pub mut:
	id                                  u32
	farmerid                            u32    // link back to farmer who owns the nodegroup, is a user?
	secret                              string // only visible by farmer, in future encrypted, used to boot a node
	description                         string
	slapolicy                           SLAPolicy
	pricingpolicy                       PricingPolicy
	compute_slice_normalized_pricing_cc f64 // pricing in CC - cloud credit, per 2GB node slice
	storage_slice_normalized_pricing_cc f64 // pricing in CC - cloud credit, per 1GB storage slice
	reputation                          int = 50 // between 0 and 100, earned over time
	uptime                              int // between 0 and 100, set by system, farmer has no ability to set this
}

pub struct SLAPolicy {
pub mut:
	sla_uptime         int // should +90
	sla_bandwidth_mbit int // minimal mbits we can expect avg over 1h per node, 0 means we don't guarantee
	sla_penalty        int // 0-100, percent of money given back in relation to month if sla breached, e.g. 200 means we return 2 months worth of rev if sla missed
}

pub struct PricingPolicy {
pub mut:
	marketplace_year_discounts []int = [30, 40, 50] // e.g. 30,40,50 means if user has more CC in wallet than 1 year utilization on all his purchaes then this provider gives 30%, 2Y 40%, ...
	volume_discounts           []int = [10, 20, 30] // e.g. 10,20,30
}
