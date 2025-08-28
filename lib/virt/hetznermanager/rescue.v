module hetznermanager

import freeflowuniverse.herolib.core.texttools
import time
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.builder
import os

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
	sshkey_name  string @[required]
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
			console.print_debug('test server ${serverinfo.server_name} is in rescue mode?')
			mut b := builder.new()!
			mut n := b.node_new(ipaddr: serverinfo.server_ip)!

			res := n.exec(cmd: 'ls /root/.oldroot/nfs/install/installimage', stdout: false) or {
				'ERROR'
			}
			if res.contains('nfs/install/installimage') {
				console.print_debug('server ${serverinfo.server_name} is in rescue mode')
				return serverinfo
			}
		}
		serverinfo.rescue = false
	}
	// only do it if its not in rescue yet
	if serverinfo.rescue == false || args.reset {
		console.print_header('server ${serverinfo.server_name} goes into rescue mode')

		mut keyfps := []string{}
		if args.sshkey_name != '' {
			keyfps << h.key_get(args.sshkey_name)!.fingerprint
		} else {
			keyfps = h.keys_get()!.map(it.fingerprint)
		}

		mut conn := h.connection()!
		rescue := conn.post_json_generic[RescueInfo](
			prefix:     'boot/${serverinfo.server_number}/rescue'
			params:     {
				'os':             'linux'
				'authorized_key': keyfps[0]
			}
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
	sshkey_name          string @[required]
	raid                 bool
}

pub fn (mut h HetznerManager) ubuntu_install(args ServerInstallArgs) !&builder.Node {
	h.check_whitelist(name:args.name,id:args.id,sshkey_name:args.sshkey_name)!
	mut serverinfo := h.server_rescue(
		id:          args.id
		name:        args.name
		wait:        true
		sshkey_name: args.sshkey_name
	)!

	mut b := builder.new()!
	mut n := b.node_new(ipaddr: serverinfo.server_ip)!

	// installconfig:=$tmpl("templates/ubuntu_install.sh")
	// n.file_write("/tmp/installconfig",installconfig)!
	// n.exec_interactive("installimage -a -c /tmp/installconfig")!

	mut rstr := '-r no '
	if args.raid {
		panic("should not use RAID for now")
		rstr = '-r yes -l 1 '
	}

	n.exec(
		cmd: '
		set -ex
		echo "go into install mode, try to install ubuntu 24.04"

		if [ -d /sys/firmware/efi ]; then
			echo "UEFI system detected → need ESP"
			PARTS="/boot/efi:esp:256M,swap:swap:4G,/boot:ext3:1024M,/:btrfs:all"
		else
			echo "BIOS/legacy system detected → no ESP"
			PARTS="swap:swap:4G,/boot:ext3:1024M,/:btrfs:all"
		fi

		# installimage invocation
		/root/.oldroot/nfs/install/installimage -a -n "${args.name}" ${rstr} -i /root/.oldroot/nfs/images/Ubuntu-2404-noble-amd64-base.tar.gz -f yes -t yes -p "\$PARTS"

		reboot
		'
	)!

	os.execute_opt('ssh-keygen -R ${serverinfo.server_ip}')!

	console.print_debug('server ${serverinfo.server_name} is installed in ubuntu now, should be restarting.')

	osal.reboot_wait(
		address:      serverinfo.server_ip
		timeout_down: 60
		timeout_up:   60 * 5
	)!

	//wait 20 sec to make sure ssh is there
	osal.ssh_wait(address: serverinfo.server_ip, timeout: 20)!

	if args.hero_install {
		n.exec_silent('apt update && apt install -y mc redis')!
		n.hero_install(compile: args.hero_install_compile)!
	}

	return n
}
