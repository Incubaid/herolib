module deployer

import incubaid.herolib.mycelium.grid3.gridproxy
import incubaid.herolib.mycelium.grid3.models as grid_models
import incubaid.herolib.mycelium.grid3.gridproxy.model as gridproxy_models
import rand
import incubaid.herolib.ui.console

// Resolves the correct grid network based on the `cn.network` value.
//
// This utility function converts the custom network type of GridContracts
// to the appropriate value in `gridproxy.TFGridNet`.
//
// Returns:
//   - A `gridproxy.TFGridNet` value corresponding to the grid network.
fn resolve_network() !gridproxy.TFGridNet {
	mut cfg := get()!
	return match cfg.network {
		.dev { gridproxy.TFGridNet.dev }
		.test { gridproxy.TFGridNet.test }
		.main { gridproxy.TFGridNet.main }
		.qa { gridproxy.TFGridNet.qa }
	}
}

/*
 * This should be the node's subnet and the wireguard routing ip that should start with 100.64 then the 2nd and 3rd part of the node's subnet
*/
fn wireguard_routing_ip(ip string) string {
	parts := ip.split('.')
	return '100.64.${parts[1]}.${parts[2]}/32'
}

// Creates a new mycelium address with a randomly generated hex key
pub fn (mut deployer TFGridDeployer) mycelium_address_create() grid_models.Mycelium {
	return grid_models.Mycelium{
		hex_key: rand.string(32).bytes().hex()
		peers:   []
	}
}

fn convert_to_gigabytes(bytes u64) u64 {
	return bytes * 1024 * 1024 * 1024
}

fn pick_node(mut deployer Deployer, nodes []gridproxy_models.Node) !gridproxy_models.Node {
	mut node := ?gridproxy_models.Node(none)
	mut checked := []bool{len: nodes.len}
	mut checked_cnt := 0
	for checked_cnt < nodes.len {
		idx := int(rand.u32() % u32(nodes.len))
		if checked[idx] {
			continue
		}

		checked[idx] = true
		checked_cnt += 1
		if ping_node(mut deployer, u32(nodes[idx].twin_id)) {
			node = nodes[idx]
			break
		}
	}

	if v := node {
		return v
	} else {
		return error('No node is reachable.')
	}
}

fn ping_node(mut deployer Deployer, twin_id u32) bool {
	if _ := deployer.client.get_zos_version(twin_id) {
		return true
	} else {
		console.print_stderr('Failed to ping node with twin: ${twin_id}')
		return false
	}
}
