module core

import os

// check path is accessible, e.g. do we need sudo and are we sudo
// if ok then will just return the same path string as output
pub fn sudo_path_check(path string) !string {
	if sudo_path_ok(path)! {
		return path
	}
	return error("Can't write/delete path:${path} because of no rights.")
}

// return false if we can't work on the path
pub fn sudo_path_ok(path string) !bool {
	if sudo_rights_check()! {
		return true
	}
	// Check if path is in protected directories
	for item in ['/usr/', '/boot', '/etc', '/root/'] {
		if path.starts_with(item) {
			return false
		}
	}
	// If not in protected directories, path is accessible
	return true
}

// if we know cmd requires sudo rights
pub fn sudo_cmd(cmd string) !bool {
	cmd2 := cmd.split(' ')[0]
	if cmd2 == 'ufw' {
		return true
	}
	// TODO: need many more checks
	return false
}

// if sudo required and we are interactive then we will put sudo in front of returned cmd
pub fn sudo_cmd_check(cmd string) !string {
	// If we have sudo rights, no need to add sudo prefix
	if sudo_rights_check()! {
		return cmd
	}

	// Check if command requires sudo
	needs_sudo := sudo_cmd(cmd)!

	if !needs_sudo {
		return cmd
	}

	if interactive()! {
		return 'sudo ${cmd}'
	}

	return error("can't execute the cmd, because no sudo rights.\ncmd:'${cmd}'")
}

// check of we have sudo rights, if yes return true
pub fn sudo_rights_check() !bool {
	// Check if the user is root
	if os.getenv('USER') == 'root' {
		return true
	}
	// TOOD: we can do more
	return false
}

// Method to check if sudo is required (i.e., if the user is root or has sudo privileges)
pub fn sudo_required() !bool {
	// Check if the user is root
	if sudo_rights_check()! {
		return false
	}
	platform_ := platform()!

	if platform_ == .osx {
		return false
	}

	// Check if the user has sudo privileges (test with `sudo -v`)
	sudo_check := os.execute('sudo -v')
	return sudo_check.exit_code == 0
}
