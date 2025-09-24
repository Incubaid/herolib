module linux

import freeflowuniverse.herolib.core.playbook { PlayBook }

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'usermgmt.') {
		return
	}

	mut lf := new()!

	// Process user_create actions
	play_user_create(mut plbook, mut lf)!

	// Process user_delete actions
	play_user_delete(mut plbook, mut lf)!

	// Process sshkey_create actions
	play_sshkey_create(mut plbook, mut lf)!

	// Process sshkey_delete actions
	play_sshkey_delete(mut plbook, mut lf)!
}

fn play_user_create(mut plbook PlayBook, mut lf LinuxFactory) ! {
	mut actions := plbook.find(filter: 'usermgmt.user_create')!

	for mut action in actions {
		mut p := action.params

		mut args := UserCreateArgs{
			name:        p.get('name')!
			giteakey:    p.get_default('giteakey', '')!
			giteaurl:    p.get_default('giteaurl', '')!
			passwd:      p.get_default('passwd', '')!
			description: p.get_default('description', '')!
			email:       p.get_default('email', '')!
			tel:         p.get_default('tel', '')!
			sshkey:      p.get_default('sshkey', '')! // SSH public key
		}

		lf.user_create(args)!
		action.done = true
	}
}

fn play_user_delete(mut plbook PlayBook, mut lf LinuxFactory) ! {
	mut actions := plbook.find(filter: 'usermgmt.user_delete')!

	for mut action in actions {
		mut p := action.params

		mut args := UserDeleteArgs{
			name: p.get('name')!
		}

		lf.user_delete(args)!
		action.done = true
	}
}

fn play_sshkey_create(mut plbook PlayBook, mut lf LinuxFactory) ! {
	mut actions := plbook.find(filter: 'usermgmt.sshkey_create')!

	for mut action in actions {
		mut p := action.params

		mut args := SSHKeyCreateArgs{
			username:    p.get('username')!
			sshkey_name: p.get('sshkey_name')!
			sshkey_pub:  p.get_default('sshkey_pub', '')!
			sshkey_priv: p.get_default('sshkey_priv', '')!
		}

		lf.sshkey_create(args)!
		action.done = true
	}
}

fn play_sshkey_delete(mut plbook PlayBook, mut lf LinuxFactory) ! {
	mut actions := plbook.find(filter: 'usermgmt.sshkey_delete')!

	for mut action in actions {
		mut p := action.params

		mut args := SSHKeyDeleteArgs{
			username:    p.get('username')!
			sshkey_name: p.get('sshkey_name')!
		}

		lf.sshkey_delete(args)!
		action.done = true
	}
}
