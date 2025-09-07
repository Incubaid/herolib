module crun

import json

// Convert enum values to their string representations
fn (os OSType) to_json_string() string {
	return match os {
		.linux { 'linux' }
		.windows { 'windows' }
		.darwin { 'darwin' }
		.solaris { 'solaris' }
	}
}

fn (arch ArchType) to_json_string() string {
	return match arch {
		.amd64 { 'amd64' }
		.arm64 { 'arm64' }
		.arm { 'arm' }
		.ppc64 { 'ppc64' }
		.s390x { 's390x' }
	}
}

fn (mount_type MountType) to_json_string() string {
	return match mount_type {
		.bind { 'bind' }
		.tmpfs { 'tmpfs' }
		.nfs { 'nfs' }
		.overlay { 'overlay' }
		.devpts { 'devpts' }
		.proc { 'proc' }
		.sysfs { 'sysfs' }
	}
}

fn (option MountOption) to_json_string() string {
	return match option {
		.rw { 'rw' }
		.ro { 'ro' }
		.noexec { 'noexec' }
		.nosuid { 'nosuid' }
		.nodev { 'nodev' }
		.rbind { 'rbind' }
		.relatime { 'relatime' }
	}
}

fn (cap Capability) to_json_string() string {
	return match cap {
		.cap_chown { 'CAP_CHOWN' }
		.cap_dac_override { 'CAP_DAC_OVERRIDE' }
		.cap_dac_read_search { 'CAP_DAC_READ_SEARCH' }
		.cap_fowner { 'CAP_FOWNER' }
		.cap_fsetid { 'CAP_FSETID' }
		.cap_kill { 'CAP_KILL' }
		.cap_setgid { 'CAP_SETGID' }
		.cap_setuid { 'CAP_SETUID' }
		.cap_setpcap { 'CAP_SETPCAP' }
		.cap_linux_immutable { 'CAP_LINUX_IMMUTABLE' }
		.cap_net_bind_service { 'CAP_NET_BIND_SERVICE' }
		.cap_net_broadcast { 'CAP_NET_BROADCAST' }
		.cap_net_admin { 'CAP_NET_ADMIN' }
		.cap_net_raw { 'CAP_NET_RAW' }
		.cap_ipc_lock { 'CAP_IPC_LOCK' }
		.cap_ipc_owner { 'CAP_IPC_OWNER' }
		.cap_sys_module { 'CAP_SYS_MODULE' }
		.cap_sys_rawio { 'CAP_SYS_RAWIO' }
		.cap_sys_chroot { 'CAP_SYS_CHROOT' }
		.cap_sys_ptrace { 'CAP_SYS_PTRACE' }
		.cap_sys_pacct { 'CAP_SYS_PACCT' }
		.cap_sys_admin { 'CAP_SYS_ADMIN' }
		.cap_sys_boot { 'CAP_SYS_BOOT' }
		.cap_sys_nice { 'CAP_SYS_NICE' }
		.cap_sys_resource { 'CAP_SYS_RESOURCE' }
		.cap_sys_time { 'CAP_SYS_TIME' }
		.cap_sys_tty_config { 'CAP_SYS_TTY_CONFIG' }
		.cap_mknod { 'CAP_MKNOD' }
		.cap_lease { 'CAP_LEASE' }
		.cap_audit_write { 'CAP_AUDIT_WRITE' }
		.cap_audit_control { 'CAP_AUDIT_CONTROL' }
		.cap_setfcap { 'CAP_SETFCAP' }
		.cap_mac_override { 'CAP_MAC_OVERRIDE' }
		.cap_mac_admin { 'CAP_MAC_ADMIN' }
		.cap_syslog { 'CAP_SYSLOG' }
		.cap_wake_alarm { 'CAP_WAKE_ALARM' }
		.cap_block_suspend { 'CAP_BLOCK_SUSPEND' }
		.cap_audit_read { 'CAP_AUDIT_READ' }
	}
}

fn (rlimit RlimitType) to_json_string() string {
	return match rlimit {
		.rlimit_cpu { 'RLIMIT_CPU' }
		.rlimit_fsize { 'RLIMIT_FSIZE' }
		.rlimit_data { 'RLIMIT_DATA' }
		.rlimit_stack { 'RLIMIT_STACK' }
		.rlimit_core { 'RLIMIT_CORE' }
		.rlimit_rss { 'RLIMIT_RSS' }
		.rlimit_nproc { 'RLIMIT_NPROC' }
		.rlimit_nofile { 'RLIMIT_NOFILE' }
		.rlimit_memlock { 'RLIMIT_MEMLOCK' }
		.rlimit_as { 'RLIMIT_AS' }
		.rlimit_lock { 'RLIMIT_LOCK' }
		.rlimit_sigpending { 'RLIMIT_SIGPENDING' }
		.rlimit_msgqueue { 'RLIMIT_MSGQUEUE' }
		.rlimit_nice { 'RLIMIT_NICE' }
		.rlimit_rtprio { 'RLIMIT_RTPRIO' }
		.rlimit_rttime { 'RLIMIT_RTTIME' }
	}
}

// Main method to generate complete OCI spec JSON
pub fn (config CrunConfig) to_json() !string {
	spec_map := map[string]json.Any{}
	
	// Basic spec fields
	spec_map['ociVersion'] = config.spec.version
	
	// Platform
	spec_map['platform'] = map[string]json.Any{
		'os': config.spec.platform.os.to_json_string()
		'arch': config.spec.platform.arch.to_json_string()
	}
	
	// Process
	process_map := map[string]json.Any{}
	process_map['terminal'] = config.spec.process.terminal
	process_map['user'] = map[string]json.Any{
		'uid': int(config.spec.process.user.uid)
		'gid': int(config.spec.process.user.gid)
		'additionalGids': config.spec.process.user.additional_gids.map(int(it))
	}
	process_map['args'] = config.spec.process.args
	process_map['env'] = config.spec.process.env
	process_map['cwd'] = config.spec.process.cwd
	
	// Capabilities
	if config.spec.process.capabilities.bounding.len > 0 || 
	   config.spec.process.capabilities.effective.len > 0 ||
	   config.spec.process.capabilities.inheritable.len > 0 ||
	   config.spec.process.capabilities.permitted.len > 0 ||
	   config.spec.process.capabilities.ambient.len > 0 {
		capabilities_map := map[string]json.Any{}
		if config.spec.process.capabilities.bounding.len > 0 {
			capabilities_map['bounding'] = config.spec.process.capabilities.bounding.map(it.to_json_string())
		}
		if config.spec.process.capabilities.effective.len > 0 {
			capabilities_map['effective'] = config.spec.process.capabilities.effective.map(it.to_json_string())
		}
		if config.spec.process.capabilities.inheritable.len > 0 {
			capabilities_map['inheritable'] = config.spec.process.capabilities.inheritable.map(it.to_json_string())
		}
		if config.spec.process.capabilities.permitted.len > 0 {
			capabilities_map['permitted'] = config.spec.process.capabilities.permitted.map(it.to_json_string())
		}
		if config.spec.process.capabilities.ambient.len > 0 {
			capabilities_map['ambient'] = config.spec.process.capabilities.ambient.map(it.to_json_string())
		}
		process_map['capabilities'] = capabilities_map
	}
	
	// Rlimits
	if config.spec.process.rlimits.len > 0 {
		rlimits_array := []json.Any{}
		for rlimit in config.spec.process.rlimits {
			rlimits_array << map[string]json.Any{
				'type': rlimit.typ.to_json_string()
				'hard': int(rlimit.hard)
				'soft': int(rlimit.soft)
			}
		}
		process_map['rlimits'] = rlimits_array
	}
	
	spec_map['process'] = process_map
	
	// Root
	spec_map['root'] = map[string]json.Any{
		'path': config.spec.root.path
		'readonly': config.spec.root.readonly
	}
	
	// Hostname
	if config.spec.hostname != '' {
		spec_map['hostname'] = config.spec.hostname
	}
	
	// Mounts
	if config.spec.mounts.len > 0 {
		mounts_array := []json.Any{}
		for mount in config.spec.mounts {
			mount_map := map[string]json.Any{
				'destination': mount.destination
				'type': mount.typ.to_json_string()
				'source': mount.source
			}
			if mount.options.len > 0 {
				mount_map['options'] = mount.options.map(it.to_json_string())
			}
			mounts_array << mount_map
		}
		spec_map['mounts'] = mounts_array
	}
	
	// Linux specific configuration
	linux_map := map[string]json.Any{}
	
	// Namespaces
	if config.spec.linux.namespaces.len > 0 {
		namespaces_array := []json.Any{}
		for ns in config.spec.linux.namespaces {
			ns_map := map[string]json.Any{
				'type': ns.typ
			}
			if ns.path != '' {
				ns_map['path'] = ns.path
			}
			namespaces_array << ns_map
		}
		linux_map['namespaces'] = namespaces_array
	}
	
	// Resources
	resources_map := map[string]json.Any{}
	has_resources := false
	
	if config.spec.linux.resources.memory_limit > 0 {
		memory_map := map[string]json.Any{
			'limit': int(config.spec.linux.resources.memory_limit)
		}
		if config.spec.linux.resources.memory_reservation > 0 {
			memory_map['reservation'] = int(config.spec.linux.resources.memory_reservation)
		}
		if config.spec.linux.resources.memory_swap_limit > 0 {
			memory_map['swap'] = int(config.spec.linux.resources.memory_swap_limit)
		}
		resources_map['memory'] = memory_map
		has_resources = true
	}
	
	if config.spec.linux.resources.cpu_period > 0 || config.spec.linux.resources.cpu_quota > 0 || config.spec.linux.resources.cpu_shares > 0 {
		cpu_map := map[string]json.Any{}
		if config.spec.linux.resources.cpu_period > 0 {
			cpu_map['period'] = int(config.spec.linux.resources.cpu_period)
		}
		if config.spec.linux.resources.cpu_quota > 0 {
			cpu_map['quota'] = int(config.spec.linux.resources.cpu_quota)
		}
		if config.spec.linux.resources.cpu_shares > 0 {
			cpu_map['shares'] = int(config.spec.linux.resources.cpu_shares)
		}
		resources_map['cpu'] = cpu_map
		has_resources = true
	}
	
	if config.spec.linux.resources.pids_limit > 0 {
		resources_map['pids'] = map[string]json.Any{
			'limit': int(config.spec.linux.resources.pids_limit)
		}
		has_resources = true
	}
	
	if has_resources {
		linux_map['resources'] = resources_map
	}
	
	spec_map['linux'] = linux_map
	
	return json.encode_pretty(spec_map)
}

// Convenience method to save JSON to file
pub fn (config CrunConfig) save_to_file(path string) ! {
	json_content := config.to_json()!
	
	import freeflowuniverse.herolib.core.pathlib
	mut file := pathlib.get_file(path: path, create: true)!
	file.write(json_content)!
}