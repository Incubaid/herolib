module deployer

import incubaid.herolib.mycelium.grid3.gridproxy
import incubaid.herolib.mycelium.grid3.gridproxy.model as gridproxy_models

// TODO: put all code in relation to filtering in file filter.v
@[params]
pub struct FilterNodesArgs {
	gridproxy_models.NodeFilter
pub:
	on_hetzner bool
}

pub fn filter_nodes(args FilterNodesArgs) ![]gridproxy_models.Node {
	// Resolve the network configuration
	net := resolve_network()!

	// Create grid proxy client and retrieve the matching nodes
	mut gp_client := gridproxy.new(net: net, cache: true)!

	mut filter := args.NodeFilter
	if args.on_hetzner {
		filter.features << ['zmachine-light']
	}

	nodes := gp_client.get_nodes(filter)!
	return nodes
}

// fn get_hetzner_node_ids(nodes []gridproxy_models.Node) ![]u64 {
// 	// get farm ids that are know to be hetzner's
// 	// if we need to iterate over all nodes, maybe we should use multi-threading
// 	panic('Not Implemented')
// 	return []
// }
