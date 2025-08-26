module sshagent

import os
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console

@[heap]
pub struct SSHAgent {
pub mut:
	keys     []SSHKey
	active   bool
	homepath pathlib.Path
}

// ensure only one SSH agent is running for the current user
pub fn (mut agent SSHAgent) ensure_single_agent() ! {
	user := os.getenv('USER')
	socket_path := get_agent_socket_path(user)

	// Check if we have a valid agent already
	if agent.is_agent_responsive() {
		console.print_debug('SSH agent already running and responsive')
		return
	}

	// Kill any orphaned agents
	agent.cleanup_orphaned_agents()!

	// Start new agent with consistent socket
	agent.start_agent_with_socket(socket_path)!

	// Set environment variables
	os.setenv('SSH_AUTH_SOCK', socket_path, true)
	agent.active = true
}

// get consistent socket path per user in home directory
fn get_agent_socket_path(user string) string {
	home := os.home_dir()
	ssh_dir := '${home}/.ssh'

	// Ensure SSH directory exists with correct permissions
	if !os.exists(ssh_dir) {
		os.mkdir_all(ssh_dir) or { return '/tmp/ssh-agent-${user}.sock' }
		os.chmod(ssh_dir, 0o700) or {}
	}

	return '${ssh_dir}/hero-agent.sock'
}

// check if current agent is responsive
pub fn (mut agent SSHAgent) is_agent_responsive() bool {
	if os.getenv('SSH_AUTH_SOCK') == '' {
		return false
	}

	res := os.execute('ssh-add -l 2>/dev/null')
	return res.exit_code == 0 || res.exit_code == 1 // 1 means no keys, but agent is running
}

// cleanup orphaned ssh-agent processes
pub fn (mut agent SSHAgent) cleanup_orphaned_agents() ! {
	user := os.getenv('USER')

	// Find ssh-agent processes for current user
	res := os.execute('pgrep -u ${user} ssh-agent')
	if res.exit_code == 0 && res.output.len > 0 {
		pids := res.output.trim_space().split('\n')

		for pid in pids {
			if pid.trim_space() != '' {
				// Check if this agent has a valid socket
				if !agent.is_agent_pid_valid(pid.int()) {
					console.print_debug('Killing orphaned ssh-agent PID: ${pid}')
					os.execute('kill ${pid}')
				}
			}
		}
	}
}

// check if specific agent PID is valid and responsive
fn (mut agent SSHAgent) is_agent_pid_valid(pid int) bool {
	// Try to find socket for this PID
	res := os.execute('find /tmp -name "agent.*" -user ${os.getenv('USER')} 2>/dev/null | head -10')
	if res.exit_code != 0 {
		return false
	}

	for socket_path in res.output.split('\n') {
		if socket_path.trim_space() != '' {
			// Test if this socket responds
			old_sock := os.getenv('SSH_AUTH_SOCK')
			os.setenv('SSH_AUTH_SOCK', socket_path, true)
			test_res := os.execute('ssh-add -l 2>/dev/null')
			os.setenv('SSH_AUTH_SOCK', old_sock, true)

			if test_res.exit_code == 0 || test_res.exit_code == 1 {
				return true
			}
		}
	}
	return false
}

// start new ssh-agent with specific socket path
pub fn (mut agent SSHAgent) start_agent_with_socket(socket_path string) ! {
	// Remove existing socket if it exists
	if os.exists(socket_path) {
		os.rm(socket_path)!
	}

	// Start ssh-agent with specific socket
	cmd := 'ssh-agent -a ${socket_path}'
	res := os.execute(cmd)
	if res.exit_code != 0 {
		return error('Failed to start ssh-agent: ${res.output}')
	}

	// Verify socket was created
	if !os.exists(socket_path) {
		return error('SSH agent socket was not created at ${socket_path}')
	}

	// Set environment variable
	os.setenv('SSH_AUTH_SOCK', socket_path, true)

	// Verify agent is responsive
	if !agent.is_agent_responsive() {
		return error('SSH agent started but is not responsive')
	}

	console.print_debug('SSH agent started with socket: ${socket_path}')
}

// get agent status and diagnostics
pub fn (mut agent SSHAgent) diagnostics() map[string]string {
	mut diag := map[string]string{}

	diag['socket_path'] = os.getenv('SSH_AUTH_SOCK')
	diag['socket_exists'] = os.exists(diag['socket_path']).str()
	diag['agent_responsive'] = agent.is_agent_responsive().str()
	diag['loaded_keys_count'] = agent.keys.filter(it.loaded).len.str()
	diag['total_keys_count'] = agent.keys.len.str()

	// Count running ssh-agent processes
	user := os.getenv('USER')
	res := os.execute('pgrep -u ${user} ssh-agent | wc -l')
	diag['agent_processes'] = if res.exit_code == 0 { res.output.trim_space() } else { '0' }

	return diag
}

// get all keys from sshagent and from the local .ssh dir
pub fn (mut agent SSHAgent) init() ! {
	// first get keys out of ssh-add
	agent.keys = []SSHKey{}
	res := os.execute('ssh-add -L')
	if res.exit_code == 0 {
		for line in res.output.split('\n') {
			if line.trim(' ') == '' {
				continue
			}
			if line.contains(' ') {
				splitted := line.split(' ')
				if splitted.len < 2 {
					return error('Invalid SSH key format in agent output: ${line}')
				}
				pubkey := splitted[1]
				mut sshkey := SSHKey{
					pubkey: pubkey
					agent:  &agent
					loaded: true
				}
				if splitted[0].contains('ed25519') {
					sshkey.cat = .ed25519
					if splitted.len > 2 {
						sshkey.email = splitted[2] or { '' }
					}
				} else if splitted[0].contains('rsa') {
					sshkey.cat = .rsa
				} else {
					return error('Unsupported SSH key type in line: ${line}')
				}

				if !(agent.exists(pubkey: pubkey)) {
					// $if debug{console.print_debug("- add from agent: ${sshkey}")}
					agent.keys << sshkey
				}
			}
		}
	}

	// now get them from the filesystem
	mut fl := agent.homepath.list()!
	mut sshfiles := fl.paths.clone()
	mut pubkeypaths := sshfiles.filter(it.path.ends_with('.pub'))
	for mut pkp in pubkeypaths {
		mut c := pkp.read()!
		c = c.replace('  ', ' ').replace('  ', ' ') // deal with double spaces, or tripple (need to do this 2x
		splitted := c.trim_space().split(' ')
		if splitted.len < 2 {
			return error('Invalid public key format in file: ${pkp.path}')
		}
		mut name := pkp.name()
		name = name[0..(name.len - 4)]
		pubkey2 := splitted[1]
		// the pop makes sure the key is removed from keys in agent, this means we can add later
		mut sshkey2 := agent.get(pubkey: pubkey2) or {
			SSHKey{
				name:   name
				pubkey: pubkey2
				agent:  &agent
			}
		}
		agent.pop(sshkey2.pubkey)
		sshkey2.name = name
		if splitted[0].contains('ed25519') {
			sshkey2.cat = .ed25519
		} else if splitted[0].contains('rsa') {
			sshkey2.cat = .rsa
		} else {
			return error('Unsupported SSH key type in file: ${pkp.path}')
		}
		if splitted.len > 2 {
			sshkey2.email = splitted[2]
		}
		// $if debug{console.print_debug("- add from fs: ${sshkey2}")}
		agent.keys << sshkey2
	}
}

// returns path to sshkey
pub fn (mut agent SSHAgent) generate(name string, passphrase string) !SSHKey {
	// Validate inputs
	validated_name := validate_key_name(name)!
	validated_passphrase := validate_passphrase(passphrase)!

	dest := '${agent.homepath.path}/${validated_name}'
	if os.exists(dest) {
		os.rm(dest)!
	}
	cmd := 'ssh-keygen -t ed25519 -f ${dest} -P ${validated_passphrase} -q'
	// console.print_debug(cmd)
	rc := os.execute(cmd)
	if !(rc.exit_code == 0) {
		return error('Could not generate SSH key: ${rc.output}')
	}

	// Set secure permissions
	secure_file_permissions(dest, true)! // private key
	secure_file_permissions('${dest}.pub', false)! // public key

	agent.init()!
	return agent.get(name: validated_name) or {
		return error("Generated SSH key '${validated_name}' not found in agent after creation: ${err}")
	}
}

// unload all ssh keys
pub fn (mut agent SSHAgent) reset() ! {
	console.print_debug('Resetting SSH agent - removing all loaded keys')
	res := os.execute('ssh-add -D')
	if res.exit_code > 0 {
		return error('cannot reset sshkeys: ${res.output}')
	}
	agent.init()! // should now be empty for loaded keys
	console.print_green('✓ All SSH keys removed from agent')
}

// load the key, they key is content (private key) .
// a name is required
pub fn (mut agent SSHAgent) add(name string, privkey_ string) !SSHKey {
	// Validate inputs
	validated_name := validate_key_name(name)!
	validated_privkey := validate_private_key(privkey_)!

	mut privkey := validated_privkey
	path := '${agent.homepath.path}/${validated_name}'

	// Validate file path
	validated_path := validate_file_path(path, agent.homepath.path)!

	if os.exists(validated_path) {
		os.rm(validated_path)!
	}
	if os.exists('${validated_path}.pub') {
		os.rm('${validated_path}.pub')!
	}
	if !privkey.ends_with('\n') {
		privkey += '\n'
	}
	os.write_file(validated_path, privkey)!
	secure_file_permissions(validated_path, true)! // private key

	res4 := os.execute('ssh-keygen -y -f ${validated_path} > ${validated_path}.pub')
	if res4.exit_code > 0 {
		return error('Cannot generate public key from private key: ${res4.output}')
	}
	secure_file_permissions('${validated_path}.pub', false)! // public key

	return agent.load(validated_path)!
}

// load key starting from path to private key
pub fn (mut agent SSHAgent) load(keypath string) !SSHKey {
	if !os.exists(keypath) {
		return error('cannot find sshkey: ${keypath}')
	}
	if keypath.ends_with('.pub') {
		return error('can only load private keys')
	}
	name := keypath.split('/').last()
	os.chmod(keypath, 0o600)!
	res := os.execute('ssh-add ${keypath}')
	if res.exit_code > 0 {
		return error('cannot add ssh-key with path ${keypath}.\n${res.output}')
	}
	agent.init()!
	return agent.get(name: name) or {
		return error("Cannot find SSH key '${name}' in agent after loading from '${keypath}': ${err}")
	}
}

// forget the specified key
pub fn (mut agent SSHAgent) forget(name string) ! {
	console.print_debug('Forgetting SSH key: ${name}')
	mut key := agent.get(name: name) or { return error('SSH key "${name}" not found in agent') }
	agent.pop(key.pubkey)
	key.forget()!
	console.print_green('✓ SSH key "${name}" removed from agent')
}

pub fn (mut agent SSHAgent) str() string {
	mut out := []string{}
	out << '\n## SSHAGENT:\n'
	for mut key in agent.keys {
		out << key.str()
	}
	return out.join_lines() + '\n'
}

pub fn (mut agent SSHAgent) keys_loaded() ![]SSHKey {
	return agent.keys.filter(it.loaded)
}
