module playcmds

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.builder
import freeflowuniverse.herolib.osal.sshagent

pub fn play_ssh(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'sshagent.') {
		return
	}

	// Get or create a single SSH agent instance
	mut agent := sshagent.new_single(sshagent.SSHAgentNewArgs{})!

	// TO IMPLEMENT:

	// // Process sshagent.check actions
	// mut check_actions := plbook.find(filter: 'sshagent.check')!
	// for mut action in check_actions {
	// 	agent.agent_check()!
	// 	action.done = true
	// }

	// // Process sshagent.sshkey_create actions
	// mut create_actions := plbook.find(filter: 'sshagent.sshkey_create')!
	// for mut action in create_actions {
	// 	mut p := action.params
	// 	name := p.get('name')!
	// 	passphrase := p.get_default('passphrase', '')!

	// 	agent.sshkey_create(name, passphrase)!
	// 	action.done = true
	// }

	// // Process sshagent.sshkey_delete actions
	// mut delete_actions := plbook.find(filter: 'sshagent.sshkey_delete')!
	// for mut action in delete_actions {
	// 	mut p := action.params
	// 	name := p.get('name')!

	// 	agent.sshkey_delete(name)!
	// 	action.done = true
	// }

	// // Process sshagent.sshkey_load actions
	// mut load_actions := plbook.find(filter: 'sshagent.sshkey_load')!
	// for mut action in load_actions {
	// 	mut p := action.params
	// 	name := p.get('name')!

	// 	agent.sshkey_load(name)!
	// 	action.done = true
	// }

	// // Process sshagent.sshkey_check actions
	// mut check_key_actions := plbook.find(filter: 'sshagent.sshkey_check')!
	// for mut action in check_key_actions {
	// 	mut p := action.params
	// 	name := p.get('name')!

	// 	agent.sshkey_check(name)!
	// 	action.done = true
	// }

	// // Process sshagent.remote_copy actions
	// mut remote_copy_actions := plbook.find(filter: 'sshagent.remote_copy')!
	// for mut action in remote_copy_actions {
	// 	mut p := action.params
	// 	node_addr := p.get('node_addr')!
	// 	key_name := p.get('name')!

	// 	agent.remote_copy(node_addr, key_name)!
	// 	action.done = true
	// }

	// // Process sshagent.remote_auth actions
	// mut remote_auth_actions := plbook.find(filter: 'sshagent.remote_auth')!
	// for mut action in remote_auth_actions {
	// 	mut p := action.params
	// 	node_addr := p.get('node_addr')!
	// 	key_name := p.get('name')!

	// 	agent.remote_auth(node_addr, key_name)!
	// 	action.done = true
	// }
}
