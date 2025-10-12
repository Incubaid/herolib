module builder

import incubaid.herolib.core.playbook
import incubaid.herolib.ui.console

// execute a playbook which can build nodes
pub fn play(mut plbook playbook.PlayBook) ! {
	mut b := new()!

	// Process actions to configure nodes
	actions := plbook.find(filter: 'node.new')!
	for action in actions {
		mut p := action.params
		mut n := b.node_new(
			name:   p.get_default('name', '')!
			ipaddr: p.get_default('ipaddr', '')!
			user:   p.get_default('user', 'root')!
			debug:  p.get_default_false('debug')
			reload: p.get_default_false('reload')
		)!
		console.print_header('Created node: ${n.name}')
	}

	// Process 'cmd.run' actions to execute commands on nodes
	cmd_actions := plbook.find(filter: 'cmd.run')!
	for action in cmd_actions {
		mut p := action.params
		node_name := p.get('node')!
		cmd := p.get('cmd')!

		// a bit ugly but we don't have node management in a central place yet
		// this will get the node created previously
		// we need a better way to get the nodes, maybe from a global scope
		mut found_node := &Node{
			factory: &b
		}
		mut found := false
		nodes_to_find := plbook.find(filter: 'node.new')!
		for node_action in nodes_to_find {
			mut node_p := node_action.params
			if node_p.get_default('name', '')! == node_name {
				found_node = b.node_new(
					name:   node_p.get_default('name', '')!
					ipaddr: node_p.get_default('ipaddr', '')!
					user:   node_p.get_default('user', 'root')!
				)!
				found = true
				break
			}
		}

		if !found {
			return error('Could not find node with name ${node_name}')
		}

		console.print_debug('Executing command on node ${found_node.name}:\n${cmd}')
		result := found_node.exec_cmd(cmd: cmd)!
		console.print_debug('Result:\n${result}')
	}
}
