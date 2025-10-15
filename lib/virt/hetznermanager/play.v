// File: lib/virt/hetznermanager/play.v
module hetznermanager

import incubaid.herolib.core.playbook { PlayBook }

// play processes playbook actions for the hetznermanager module.
// It allows configuring and managing Hetzner servers through heroscript.
pub fn play2(mut plbook PlayBook) ! {
	// Handle rescue actions
	for mut action in plbook.find(filter: 'hetznermanager.server_rescue')! {
		mut p := action.params
		mut cl := get(name: p.get_default('instance', 'default')!)!

		id := p.get_int_default('id', 0)!
		server_name := p.get_default('server_name', '')!
		wait := p.get_default_true('wait')
		hero_install := p.get_default_false('hero_install')
		reset := p.get_default_false('reset')
		retry := p.get_int_default('retry', 3)!

		if server_name == '' && id == 0 {
			return error("For ${action.actor}.${action.name}, either 'server_name' or 'id' must be provided.")
		}

		cl.server_rescue(
			id:           id
			name:         server_name
			wait:         wait
			hero_install: hero_install
			reset:        reset
			retry:        retry
		)!

		action.done = true
	}

	// Handle ubuntu install actions
	for mut action in plbook.find(filter: 'hetznermanager.ubuntu_install')! {
		mut p := action.params
		mut cl := get(name: p.get_default('instance', 'default')!)!

		id := p.get_int_default('id', 0)!
		server_name := p.get_default('server_name', '')!
		wait := p.get_default_true('wait')
		hero_install := p.get_default_false('hero_install')
		hero_install_compile := p.get_default_false('hero_install_compile')
		raid := p.get_default_false('raid')

		if server_name == '' && id == 0 {
			return error("For ${action.actor}.${action.name}, either 'server_name' or 'id' must be provided.")
		}

		cl.ubuntu_install(
			id:                   id
			name:                 server_name
			wait:                 wait
			hero_install:         hero_install
			hero_install_compile: hero_install_compile
			raid:                 raid
		)!

		action.done = true
	}

	// Handle server reset actions
	for mut action in plbook.find(filter: 'hetznermanager.server_reset')! {
		mut p := action.params
		mut cl := get(name: p.get_default('instance', 'default')!)!
		id := p.get_int_default('id', 0)!
		server_name := p.get_default('server_name', '')!
		wait := p.get_default_true('wait')
		msg := p.get_default('msg', '')!

		if server_name == '' && id == 0 {
			return error("For ${action.actor}.${action.name}, either 'server_name' or 'id' must be provided.")
		}

		cl.server_reset(
			id:   id
			name: server_name
			wait: wait
			msg:  msg
		)!

		action.done = true
	}

	// Handle SSH key creation
	for mut action in plbook.find(filter: 'hetznermanager.key_create')! {
		mut p := action.params
		mut cl := get(name: p.get_default('instance', 'default')!)!

		key_name := p.get('key_name')!
		data := p.get('data')!

		cl.key_create(key_name, data)!

		action.done = true
	}

	// Handle SSH key deletion
	for mut action in plbook.find(filter: 'hetznermanager.key_delete')! {
		mut p := action.params
		mut cl := get(name: p.get_default('instance', 'default')!)!

		key_name := p.get('key_name')!

		cl.key_delete(key_name)!

		action.done = true
	}
}
