module sshagent

import freeflowuniverse.herolib.core.playbook { PlayBook }

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'sshagent.') {
		return
	}

	// Get or create a single SSH agent instance
	mut agent := new_single()!

	// Process sshagent.check actions
	mut check_actions := plbook.find(filter: 'sshagent.check')!
	for mut action in check_actions {
		agent_check(mut agent)!
		action.done = true
	}

	// Process sshagent.sshkey_create actions
	mut create_actions := plbook.find(filter: 'sshagent.sshkey_create')!
	for mut action in create_actions {
		mut p := action.params
		name := p.get('name')!
		passphrase := p.get_default('passphrase', '')!

		sshkey_create(mut agent, name, passphrase)!
		action.done = true
	}

	// Process sshagent.sshkey_delete actions
	mut delete_actions := plbook.find(filter: 'sshagent.sshkey_delete')!
	for mut action in delete_actions {
		mut p := action.params
		name := p.get('name')!

		sshkey_delete(mut agent, name)!
		action.done = true
	}

	// Process sshagent.sshkey_load actions
	mut load_actions := plbook.find(filter: 'sshagent.sshkey_load')!
	for mut action in load_actions {
		mut p := action.params
		name := p.get('name')!

		sshkey_load(mut agent, name)!
		action.done = true
	}

	// Process sshagent.sshkey_check actions
	mut check_key_actions := plbook.find(filter: 'sshagent.sshkey_check')!
	for mut action in check_key_actions {
		mut p := action.params
		name := p.get('name')!

		sshkey_check(mut agent, name)!
		action.done = true
	}

	// Process sshagent.remote_copy actions
	mut remote_copy_actions := plbook.find(filter: 'sshagent.remote_copy')!
	for mut action in remote_copy_actions {
		mut p := action.params
		node_addr := p.get('node')!
		key_name := p.get('name')!

		remote_copy(mut agent, node_addr, key_name)!
		action.done = true
	}

	// Process sshagent.remote_auth actions
	mut remote_auth_actions := plbook.find(filter: 'sshagent.remote_auth')!
	for mut action in remote_auth_actions {
		mut p := action.params
		node_addr := p.get('node')!
		key_name := p.get('name')!

		remote_auth(mut agent, node_addr, key_name)!
		action.done = true
	}
}
