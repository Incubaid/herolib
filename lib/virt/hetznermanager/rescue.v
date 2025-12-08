module hetznermanager

import time
import incubaid.herolib.ui.console
import incubaid.herolib.osal.core as osal
import incubaid.herolib.builder
import os

// Ubuntu installation timeout constants
const install_timeout_seconds = 600 // 10 minutes max for installation
const install_poll_interval_seconds = 5 // Check installation status every 5 seconds
const install_progress_interval = 6 // Show progress every 6 polls (30 seconds)

// ///////////////////////////RESCUE

pub struct RescueInfo {
pub mut:
	server_ip       string
	server_ipv6_net string
	server_number   int
	os              string
	arch            int
	active          bool
	password        string
	authorized_key  []string
	host_key        []string
}

pub struct ServerRescueArgs {
pub mut:
	id           int
	name         string
	wait         bool = true
	hero_install bool
	reset        bool // ask to do reset/rescue even if its already in that state
	retry        int = 3
}

pub fn (mut h HetznerManager) server_rescue(args_ ServerRescueArgs) !ServerInfoDetailed {
	h.check_whitelist(args_)!
	if args_.retry > 1 {
		for _ in 0 .. args_.retry - 1 {
			return h.server_rescue_internal(args_) or { continue }
		}
		console.print_header('server ${args_.name} failed to rescue we retry: now ${args_.retry} attempts')
	}
	return h.server_rescue_internal(args_)!
}

fn (mut h HetznerManager) server_rescue_internal(args_ ServerRescueArgs) !ServerInfoDetailed {
	mut args := args_
	mut serverinfo := h.server_info_get(id: args.id, name: args.name)!

	os.execute_opt('ssh-keygen -R ${serverinfo.server_ip}')!

	if serverinfo.rescue && !args.reset {
		if osal.ssh_test(address: serverinfo.server_ip, port: 22)! == .ok {
			console.print_debug('test server ${serverinfo.server_name} - checking if actually in rescue mode...')
			mut b := builder.new()!
			mut n := b.node_new(ipaddr: serverinfo.server_ip)!

			// Check if the server is actually in rescue mode using file_exists
			if n.file_exists('/root/.oldroot/nfs/install/installimage') {
				console.print_debug('server ${serverinfo.server_name} is in rescue mode')
				return serverinfo
			}

			// Server is reachable but not in rescue mode - check if it's running Ubuntu
			// This happens when the API reports rescue=true but the server already booted into the installed OS
			if n.platform == .ubuntu {
				console.print_debug('server ${serverinfo.server_name} is already running Ubuntu, not in rescue mode')
			} else {
				console.print_debug('server ${serverinfo.server_name} is running ${n.platform}, not in rescue mode')
			}
			// Server is not in rescue mode - the rescue flag in API is stale
			serverinfo.rescue = false
		} else {
			// SSH not reachable - server might be rebooting or in unknown state
			serverinfo.rescue = false
		}
	}
	// only do it if its not in rescue yet
	if serverinfo.rescue == false || args.reset {
		console.print_header('server ${serverinfo.server_name} goes into rescue mode')

		// Get SSH keys based on sshkey mode ('*', 'default', or specific key name)
		keys := h.get_keys_for_rescue()!

		// Build URL-encoded data with multiple authorized_key[] parameters
		// Hetzner API expects: authorized_key[]=fp1&authorized_key[]=fp2&...
		mut data_parts := ['os=linux']
		for key in keys {
			data_parts << 'authorized_key[]=${key.fingerprint}'
		}
		post_data := data_parts.join('&')

		console.print_debug('Using ${keys.len} SSH key(s) for rescue mode')

		mut conn := h.connection()!
		rescue := conn.post_json_generic[RescueInfo](
			prefix:     'boot/${serverinfo.server_number}/rescue'
			data:       post_data
			dict_key:   'rescue'
			dataformat: .urlencoded
		)!

		console.print_debug('Request for hetzner rescue done.\n${rescue}')

		h.server_reset(
			id:   args.id
			name: args.name
			wait: args.wait
			msg:  ' to get up and running in rescue mode.'
		)!

		os.execute_opt('ssh-keygen -R ${serverinfo.server_ip}')!
	}

	if args.hero_install {
		args.wait = true
	}

	if args.wait {
		mut b := builder.new()!
		mut n := b.node_new(ipaddr: serverinfo.server_ip)!
		n.exec_silent('apt update && apt install -y mc redis')!
		if args.hero_install {
			n.hero_install()!
		}
	}

	mut serverinfo2 := h.server_info_get(id: args.id, name: args.name)!

	return serverinfo2
}

pub fn (mut h HetznerManager) server_rescue_node(args ServerRescueArgs) !&builder.Node {
	mut serverinfo := h.server_rescue(args)!

	mut b := builder.new()!
	mut n := b.node_new(ipaddr: serverinfo.server_ip)!

	return n
}

pub struct ServerInstallArgs {
pub mut:
	id                   int
	name                 string
	wait                 bool = true
	hero_install         bool
	hero_install_compile bool
	raid                 bool
	install_timeout      int = install_timeout_seconds // timeout in seconds for installation
	reinstall            bool // if true, always reinstall even if Ubuntu is already running
}

pub fn (mut h HetznerManager) ubuntu_install(args ServerInstallArgs) !&builder.Node {
	h.check_whitelist(name: args.name, id: args.id)!
	mut serverinfo := h.server_info_get(id: args.id, name: args.name)!

	// Check if Ubuntu is already installed and running (skip reinstallation unless forced)
	if !args.reinstall {
		if osal.ssh_test(address: serverinfo.server_ip, port: 22)! == .ok {
			mut b := builder.new()!
			mut n := b.node_new(ipaddr: serverinfo.server_ip)!

			// Check if server is running Ubuntu and NOT in rescue mode using Node's methods
			is_rescue := n.file_exists('/root/.oldroot/nfs/install/installimage')

			if n.platform == .ubuntu && !is_rescue {
				console.print_debug('server ${serverinfo.server_name} is already running Ubuntu, skipping installation')

				// Inject all SSH keys from Hetzner account into the server
				console.print_debug('Injecting SSH keys from Hetzner account into ${serverinfo.server_name}')
				pubkeys := h.get_pubkeys_data()!
				
				if pubkeys.len > 0 {
					// Read existing authorized_keys
					existing_keys := n.exec(cmd: 'cat /root/.ssh/authorized_keys 2>/dev/null || echo ""', stdout: false) or { '' }
					
					// Combine existing keys with new keys (avoid duplicates)
					mut all_keys := existing_keys.split('\n').filter(it.trim_space().len > 0)
					
					for pubkey in pubkeys {
						key_trimmed := pubkey.trim_space()
						if key_trimmed.len > 0 && !all_keys.contains(key_trimmed) {
							all_keys << key_trimmed
						}
					}
					
					// Write all keys back
					combined_keys := all_keys.join('\n') + '\n'
					n.exec(cmd: 'mkdir -p /root/.ssh && chmod 700 /root/.ssh', stdout: false)!
					n.file_write('/root/.ssh/authorized_keys', combined_keys)!
					n.exec(cmd: 'chmod 600 /root/.ssh/authorized_keys', stdout: false)!
					
					console.print_debug('Injected ${pubkeys.len} SSH key(s) into ${serverinfo.server_name}')
				}

				// Still install hero if requested
				if args.hero_install {
					n.exec_silent('apt update && apt install -y mc redis libpq5 libpq-dev')!
					n.hero_install(compile: args.hero_install_compile)!
				}

				return n
			}
		}
	}

	// Server needs Ubuntu installation - go into rescue mode
	serverinfo = h.server_rescue(
		id:   args.id
		name: args.name
		wait: true
	)!

	// Get all SSH public keys to copy to the installed system
	pubkeys := h.get_pubkeys_data()!
	ssh_pubkeys := pubkeys.join('\n')

	mut b := builder.new()!
	mut n := b.node_new(ipaddr: serverinfo.server_ip)!

	// installconfig:=$tmpl("templates/ubuntu_install.sh")
	// n.file_write("/tmp/installconfig",installconfig)!
	// n.exec_interactive("installimage -a -c /tmp/installconfig")!

	mut rstr := '-r no '
	if args.raid {
		panic('should not use RAID for now')
		rstr = '-r yes -l 1 '
	}

	// Write the installation script to the server
	// We run it with nohup in the background to avoid SSH timeout during long installations
	install_script := '#!/bin/bash
set -e
echo "go into install mode, try to install ubuntu 24.04"

# Cleanup any previous installation state
rm -f /tmp/install_complete /tmp/install_failed

if [ -d /sys/firmware/efi ]; then
	echo "UEFI system detected → need ESP"
	PARTS="/boot/efi:esp:256M,swap:swap:4G,/boot:ext3:1024M,/:btrfs:all"
else
	echo "BIOS/legacy system detected → no ESP"
	PARTS="swap:swap:4G,/boot:ext3:1024M,/:btrfs:all"
fi

# installimage invocation with error handling
if ! /root/.oldroot/nfs/install/installimage -a -n "${args.name}" ${rstr} -i /root/.oldroot/nfs/images/Ubuntu-2404-noble-amd64-base.tar.gz -f yes -t yes -p "\$PARTS"; then
	echo "INSTALL_FAILED" > /tmp/install_failed
	echo "installimage failed, check /root/debug.txt for details"
	exit 1
fi

# Copy SSH keys to the installed system before rebooting
# After installimage, the new system is mounted at /mnt
echo "Copying SSH keys to installed system..."
mkdir -p /mnt/root/.ssh
chmod 700 /mnt/root/.ssh
cat > /mnt/root/.ssh/authorized_keys << "EOF_SSH_KEYS"
${ssh_pubkeys}
EOF_SSH_KEYS
chmod 600 /mnt/root/.ssh/authorized_keys
echo "SSH keys copied successfully"

# Mark installation as complete before rebooting
# sync to ensure marker file is written to disk before reboot
echo "INSTALL_COMPLETE" > /tmp/install_complete
sync

reboot
'

	n.file_write('/tmp/ubuntu_install.sh', install_script)!

	// Start the installation in background using nohup to avoid SSH timeout
	// The script will run independently of the SSH session
	n.exec(
		cmd:    'chmod +x /tmp/ubuntu_install.sh && nohup /tmp/ubuntu_install.sh > /tmp/install.log 2>&1 &'
		stdout: false
	)!

	console.print_debug('Installation script started in background, waiting for completion...')

	// Poll for completion by checking if the marker file exists or if the server goes down (reboot)
	max_iterations := args.install_timeout / install_poll_interval_seconds
	mut install_complete := false
	for i := 0; i < max_iterations; i++ {
		time.sleep(install_poll_interval_seconds * time.second)

		// Check if server is still up and installation status
		result := n.exec(
			cmd:    'cat /tmp/install_failed 2>/dev/null && echo "FAILED" || (cat /tmp/install_complete 2>/dev/null || echo "NOT_COMPLETE")'
			stdout: false
		) or {
			// SSH connection failed - server might be rebooting after successful installation
			console.print_debug('SSH connection lost - server is likely rebooting after installation')
			install_complete = true
			break
		}

		// Check for installation failure
		if result.contains('INSTALL_FAILED') || result.contains('FAILED') {
			// Try to get error details from install log
			error_log := n.exec(
				cmd:    'tail -20 /tmp/install.log 2>/dev/null || cat /root/debug.txt 2>/dev/null || echo "No error details available"'
				stdout: false
			) or { 'Could not retrieve error details' }
			return error('Installation failed: ${error_log.trim_space()}')
		}

		if result.contains('INSTALL_COMPLETE') {
			console.print_debug('Installation complete, server should reboot soon')
			install_complete = true
			break
		}

		// Show progress at configured interval
		if i % install_progress_interval == 0 {
			// Try to get the last line of the install log for progress
			log_tail := n.exec(
				cmd:    'tail -3 /tmp/install.log 2>/dev/null || echo "waiting..."'
				stdout: false
			) or { 'waiting...' }
			console.print_debug('Installation in progress: ${log_tail.trim_space()}')
		}
	}

	if !install_complete {
		return error('Installation timed out after ${args.install_timeout} seconds')
	}

	os.execute_opt('ssh-keygen -R ${serverinfo.server_ip}')!

	console.print_debug('server ${serverinfo.server_name} is installed in ubuntu now, should be restarting.')

	osal.reboot_wait(
		address:      serverinfo.server_ip
		timeout_down: 60
		timeout_up:   60 * 5
	)!

	console.print_debug('server ${serverinfo.server_name} is reacheable over ping, lets now try ssh.')

	// wait 20 seconds to make sure ssh is there (timeout is in milliseconds)
	osal.ssh_wait(address: serverinfo.server_ip, timeout: 20000)!

	console.print_debug('server ${serverinfo.server_name} is reacheable over ssh, lets now install hero if asked for.')

	// Create a new node connection to the freshly installed Ubuntu system
	// The old 'n' was connected to the rescue system which no longer exists after reboot
	mut b2 := builder.new()!
	mut n2 := b2.node_new(ipaddr: serverinfo.server_ip)!

	if args.hero_install {
		n2.exec_silent('apt update && apt install -y mc redis libpq5 libpq-dev')!
		n2.hero_install(compile: args.hero_install_compile)!
	}

	return n2
}
