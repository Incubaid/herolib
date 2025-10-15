module herorun2

import incubaid.herolib.osal.core as osal

// Package installer functions for herorun dependencies
// Each function installs a specific package on the remote node

// Install runc container runtime
pub fn install_runc(node_ip string, user string) ! {
	// Check if runc is already installed
	check_cmd := 'ssh ${user}@${node_ip} "command -v runc"'
	result := osal.execute_silent(check_cmd) or { '' }

	if result != '' {
		// Already installed
		return
	}

	// Detect OS on remote node
	os_detect_cmd := "ssh ${user}@${node_ip} \"cat /etc/os-release | grep ^ID= | cut -d= -f2 | tr -d \\\"\" 2>/dev/null || echo \"unknown\""
	os_result := osal.execute_silent(os_detect_cmd) or { 'unknown' }
	os_id := os_result.trim_space()

	mut install_cmd := ''

	match os_id {
		'ubuntu', 'debian' {
			install_cmd = 'ssh ${user}@${node_ip} "apt-get update && apt-get install -y runc"'
		}
		'alpine' {
			install_cmd = 'ssh ${user}@${node_ip} "apk add --no-cache runc"'
		}
		'centos', 'rhel', 'fedora' {
			install_cmd = 'ssh ${user}@${node_ip} "if command -v dnf >/dev/null 2>&1; then dnf install -y runc; else yum install -y runc; fi"'
		}
		else {
			return error('Unsupported OS for runc installation: ${os_id}. Please install runc manually.')
		}
	}

	// Execute installation
	osal.exec(cmd: install_cmd, stdout: false, name: 'install_runc')!

	// Verify installation
	verify_cmd := 'ssh ${user}@${node_ip} "runc --version"'
	verify_result := osal.execute_silent(verify_cmd) or { '' }

	if verify_result == '' {
		return error('runc installation failed - command not found after installation')
	}
}

// Install tmux terminal multiplexer
pub fn install_tmux(node_ip string, user string) ! {
	// Check if tmux is already installed
	check_cmd := 'ssh ${user}@${node_ip} "command -v tmux"'
	result := osal.execute_silent(check_cmd) or { '' }

	if result != '' {
		// Already installed
		return
	}

	// Detect OS on remote node
	os_detect_cmd := "ssh ${user}@${node_ip} \"cat /etc/os-release | grep ^ID= | cut -d= -f2 | tr -d \\\"\" 2>/dev/null || echo \"unknown\""
	os_result := osal.execute_silent(os_detect_cmd) or { 'unknown' }
	os_id := os_result.trim_space()

	mut install_cmd := ''

	match os_id {
		'ubuntu', 'debian' {
			install_cmd = 'ssh ${user}@${node_ip} "apt-get update && apt-get install -y tmux"'
		}
		'alpine' {
			install_cmd = 'ssh ${user}@${node_ip} "apk add --no-cache tmux"'
		}
		'centos', 'rhel', 'fedora' {
			install_cmd = 'ssh ${user}@${node_ip} "if command -v dnf >/dev/null 2>&1; then dnf install -y tmux; else yum install -y tmux; fi"'
		}
		else {
			return error('Unsupported OS for tmux installation: ${os_id}. Please install tmux manually.')
		}
	}

	// Execute installation
	osal.exec(cmd: install_cmd, stdout: false, name: 'install_tmux')!

	// Verify installation
	verify_cmd := 'ssh ${user}@${node_ip} "tmux -V"'
	verify_result := osal.execute_silent(verify_cmd) or { '' }

	if verify_result == '' {
		return error('tmux installation failed - command not found after installation')
	}
}

// Install curl for downloading files
pub fn install_curl(node_ip string, user string) ! {
	// Check if curl is already installed
	check_cmd := 'ssh ${user}@${node_ip} "command -v curl"'
	result := osal.execute_silent(check_cmd) or { '' }

	if result != '' {
		// Already installed
		return
	}

	// Detect OS on remote node
	os_detect_cmd := "ssh ${user}@${node_ip} \"cat /etc/os-release | grep ^ID= | cut -d= -f2 | tr -d \\\"\" 2>/dev/null || echo \"unknown\""
	os_result := osal.execute_silent(os_detect_cmd) or { 'unknown' }
	os_id := os_result.trim_space()

	mut install_cmd := ''

	match os_id {
		'ubuntu', 'debian' {
			install_cmd = 'ssh ${user}@${node_ip} "apt-get update && apt-get install -y curl"'
		}
		'alpine' {
			install_cmd = 'ssh ${user}@${node_ip} "apk add --no-cache curl"'
		}
		'centos', 'rhel', 'fedora' {
			install_cmd = 'ssh ${user}@${node_ip} "if command -v dnf >/dev/null 2>&1; then dnf install -y curl; else yum install -y curl; fi"'
		}
		else {
			return error('Unsupported OS for curl installation: ${os_id}. Please install curl manually.')
		}
	}

	// Execute installation
	osal.exec(cmd: install_cmd, stdout: false, name: 'install_curl')!

	// Verify installation
	verify_cmd := 'ssh ${user}@${node_ip} "curl --version"'
	verify_result := osal.execute_silent(verify_cmd) or { '' }

	if verify_result == '' {
		return error('curl installation failed - command not found after installation')
	}
}

// Install tar for archive extraction
pub fn install_tar(node_ip string, user string) ! {
	// Check if tar is already installed
	check_cmd := 'ssh ${user}@${node_ip} "command -v tar"'
	result := osal.execute_silent(check_cmd) or { '' }

	if result != '' {
		// Already installed
		return
	}

	// Detect OS on remote node
	os_detect_cmd := "ssh ${user}@${node_ip} \"cat /etc/os-release | grep ^ID= | cut -d= -f2 | tr -d \\\"\" 2>/dev/null || echo \"unknown\""
	os_result := osal.execute_silent(os_detect_cmd) or { 'unknown' }
	os_id := os_result.trim_space()

	mut install_cmd := ''

	match os_id {
		'ubuntu', 'debian' {
			install_cmd = 'ssh ${user}@${node_ip} "apt-get update && apt-get install -y tar"'
		}
		'alpine' {
			install_cmd = 'ssh ${user}@${node_ip} "apk add --no-cache tar"'
		}
		'centos', 'rhel', 'fedora' {
			install_cmd = 'ssh ${user}@${node_ip} "if command -v dnf >/dev/null 2>&1; then dnf install -y tar; else yum install -y tar; fi"'
		}
		else {
			return error('Unsupported OS for tar installation: ${os_id}. Please install tar manually.')
		}
	}

	// Execute installation
	osal.exec(cmd: install_cmd, stdout: false, name: 'install_tar')!

	// Verify installation
	verify_cmd := 'ssh ${user}@${node_ip} "tar --version"'
	verify_result := osal.execute_silent(verify_cmd) or { '' }

	if verify_result == '' {
		return error('tar installation failed - command not found after installation')
	}
}

// Install git for version control
pub fn install_git(node_ip string, user string) ! {
	// Check if git is already installed
	check_cmd := 'ssh ${user}@${node_ip} "command -v git"'
	result := osal.execute_silent(check_cmd) or { '' }

	if result != '' {
		// Already installed
		return
	}

	// Detect OS on remote node
	os_detect_cmd := "ssh ${user}@${node_ip} \"cat /etc/os-release | grep ^ID= | cut -d= -f2 | tr -d \\\"\" 2>/dev/null || echo \"unknown\""
	os_result := osal.execute_silent(os_detect_cmd) or { 'unknown' }
	os_id := os_result.trim_space()

	mut install_cmd := ''

	match os_id {
		'ubuntu', 'debian' {
			install_cmd = 'ssh ${user}@${node_ip} "apt-get update && apt-get install -y git"'
		}
		'alpine' {
			install_cmd = 'ssh ${user}@${node_ip} "apk add --no-cache git"'
		}
		'centos', 'rhel', 'fedora' {
			install_cmd = 'ssh ${user}@${node_ip} "if command -v dnf >/dev/null 2>&1; then dnf install -y git; else yum install -y git; fi"'
		}
		else {
			return error('Unsupported OS for git installation: ${os_id}. Please install git manually.')
		}
	}

	// Execute installation
	osal.exec(cmd: install_cmd, stdout: false, name: 'install_git')!

	// Verify installation
	verify_cmd := 'ssh ${user}@${node_ip} "git --version"'
	verify_result := osal.execute_silent(verify_cmd) or { '' }

	if verify_result == '' {
		return error('git installation failed - command not found after installation')
	}
}

// Install all required packages for herorun
pub fn install_all_requirements(node_ip string, user string) ! {
	install_curl(node_ip, user)!
	install_tar(node_ip, user)!
	install_git(node_ip, user)!
	install_tmux(node_ip, user)!
	install_runc(node_ip, user)!
}
