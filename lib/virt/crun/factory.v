module crun

import incubaid.herolib.core.texttools

@[params]
pub struct FactoryArgs {
pub mut:
	name string = 'default'
}

pub struct CrunConfig {
pub mut:
	name string
	spec Spec
}

// Convert enum values to their string representations
pub fn (mount_type MountType) to_string() string {
	return match mount_type {
		.bind { 'bind' }
		.tmpfs { 'tmpfs' }
		.proc { 'proc' }
		.sysfs { 'sysfs' }
		.devpts { 'devpts' }
		.mqueue { 'mqueue' }
		.cgroup { 'cgroup' }
		.nfs { 'nfs' }
		.overlay { 'overlay' }
	}
}

pub fn (option MountOption) to_string() string {
	return match option {
		.rw { 'rw' }
		.ro { 'ro' }
		.noexec { 'noexec' }
		.nosuid { 'nosuid' }
		.nodev { 'nodev' }
		.rbind { 'rbind' }
		.relatime { 'relatime' }
		.strictatime { 'strictatime' }
		.mode { 'mode=755' } // Default mode, can be customized
		.size { 'size=65536k' } // Default size, can be customized
	}
}

pub fn (cap Capability) to_string() string {
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

pub fn (rlimit RlimitType) to_string() string {
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

// Configuration methods with builder pattern
pub fn (mut config CrunConfig) set_command(args []string) &CrunConfig {
	config.spec.process.args = args.clone()
	return config
}

pub fn (mut config CrunConfig) set_working_dir(cwd string) &CrunConfig {
	config.spec.process.cwd = cwd
	return config
}

pub fn (mut config CrunConfig) set_user(uid u32, gid u32, additional_gids []u32) &CrunConfig {
	config.spec.process.user = User{
		uid:             uid
		gid:             gid
		additional_gids: additional_gids.clone()
	}
	return config
}

pub fn (mut config CrunConfig) add_env(key string, value string) &CrunConfig {
	// Remove existing env var with same key to avoid duplicates
	config.spec.process.env = config.spec.process.env.filter(!it.starts_with('${key}='))
	config.spec.process.env << '${key}=${value}'
	return config
}

pub fn (mut config CrunConfig) set_rootfs(path string, readonly bool) &CrunConfig {
	config.spec.root = Root{
		path:     path
		readonly: readonly
	}
	return config
}

pub fn (mut config CrunConfig) set_hostname(hostname string) &CrunConfig {
	config.spec.hostname = hostname
	return config
}

pub fn (mut config CrunConfig) set_memory_limit(limit_bytes u64) &CrunConfig {
	config.spec.linux.resources.memory.limit = limit_bytes
	return config
}

pub fn (mut config CrunConfig) set_cpu_limits(period u64, quota i64, shares u64) &CrunConfig {
	config.spec.linux.resources.cpu.period = period
	config.spec.linux.resources.cpu.quota = quota
	config.spec.linux.resources.cpu.shares = shares
	return config
}

pub fn (mut config CrunConfig) set_pids_limit(limit i64) &CrunConfig {
	config.spec.linux.resources.pids.limit = limit
	return config
}

pub fn (mut config CrunConfig) add_mount(destination string, source string, typ MountType, options []MountOption) &CrunConfig {
	config.spec.mounts << Mount{
		destination: destination
		typ:         typ.to_string()
		source:      source
		options:     options.map(it.to_string())
	}
	return config
}

pub fn (mut config CrunConfig) add_capability(cap Capability) &CrunConfig {
	cap_str := cap.to_string()

	if cap_str !in config.spec.process.capabilities.bounding {
		config.spec.process.capabilities.bounding << cap_str
	}
	if cap_str !in config.spec.process.capabilities.effective {
		config.spec.process.capabilities.effective << cap_str
	}
	if cap_str !in config.spec.process.capabilities.permitted {
		config.spec.process.capabilities.permitted << cap_str
	}
	return config
}

pub fn (mut config CrunConfig) remove_capability(cap Capability) &CrunConfig {
	cap_str := cap.to_string()

	config.spec.process.capabilities.bounding = config.spec.process.capabilities.bounding.filter(it != cap_str)
	config.spec.process.capabilities.effective = config.spec.process.capabilities.effective.filter(it != cap_str)
	config.spec.process.capabilities.permitted = config.spec.process.capabilities.permitted.filter(it != cap_str)
	return config
}

pub fn (mut config CrunConfig) add_rlimit(typ RlimitType, hard u64, soft u64) &CrunConfig {
	// Remove existing rlimit with same type to avoid duplicates
	typ_str := typ.to_string()
	config.spec.process.rlimits = config.spec.process.rlimits.filter(it.typ != typ_str)
	config.spec.process.rlimits << Rlimit{
		typ:  typ_str
		hard: hard
		soft: soft
	}
	return config
}

pub fn (mut config CrunConfig) set_no_new_privileges(value bool) &CrunConfig {
	config.spec.process.no_new_privileges = value
	return config
}

pub fn (mut config CrunConfig) set_terminal(value bool) &CrunConfig {
	config.spec.process.terminal = value
	return config
}

pub fn (mut config CrunConfig) add_masked_path(path string) &CrunConfig {
	if path !in config.spec.linux.masked_paths {
		config.spec.linux.masked_paths << path
	}
	return config
}

pub fn (mut config CrunConfig) add_readonly_path(path string) &CrunConfig {
	if path !in config.spec.linux.readonly_paths {
		config.spec.linux.readonly_paths << path
	}
	return config
}

pub fn new(mut configs map[string]&CrunConfig, args FactoryArgs) !&CrunConfig {
	name := texttools.name_fix(args.name)

	mut config := &CrunConfig{
		name: name
		spec: create_default_spec()
	}

	configs[name] = config
	return config
}

pub fn get(configs map[string]&CrunConfig, args FactoryArgs) !&CrunConfig {
	name := texttools.name_fix(args.name)
	return configs[name] or { return error('crun config with name "${name}" does not exist') }
}

fn create_default_spec() Spec {
	// Create default spec that matches the heropods template
	mut spec := Spec{
		oci_version: '1.0.2' // Set default here
		platform:    Platform{
			os:   'linux'
			arch: 'amd64'
		}
		process:     Process{
			terminal:          true
			user:              User{
				uid: 0
				gid: 0
			}
			args:              ['/bin/sh']
			env:               [
				'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
				'TERM=xterm',
			]
			cwd:               '/'
			capabilities:      Capabilities{
				bounding:    ['CAP_AUDIT_WRITE', 'CAP_KILL', 'CAP_NET_BIND_SERVICE']
				effective:   ['CAP_AUDIT_WRITE', 'CAP_KILL', 'CAP_NET_BIND_SERVICE']
				inheritable: ['CAP_AUDIT_WRITE', 'CAP_KILL', 'CAP_NET_BIND_SERVICE']
				permitted:   ['CAP_AUDIT_WRITE', 'CAP_KILL', 'CAP_NET_BIND_SERVICE']
			}
			rlimits:           [
				Rlimit{
					typ:  'RLIMIT_NOFILE'
					hard: 1024
					soft: 1024
				},
			]
			no_new_privileges: true // No JSON annotation needed here
		}
		root:        Root{
			path:     'rootfs'
			readonly: false
		}
		hostname:    'container'
		mounts:      create_default_mounts()
		linux:       Linux{
			namespaces:     create_default_namespaces()
			masked_paths:   [
				'/proc/acpi',
				'/proc/kcore',
				'/proc/keys',
				'/proc/latency_stats',
				'/proc/timer_list',
				'/proc/timer_stats',
				'/proc/sched_debug',
				'/proc/scsi',
				'/sys/firmware',
			]
			readonly_paths: [
				'/proc/asound',
				'/proc/bus',
				'/proc/fs',
				'/proc/irq',
				'/proc/sys',
				'/proc/sysrq-trigger',
			]
		}
	}

	return spec
}

fn create_default_namespaces() []LinuxNamespace {
	return [
		LinuxNamespace{
			typ: 'pid'
		},
		LinuxNamespace{
			typ: 'network'
		},
		LinuxNamespace{
			typ: 'ipc'
		},
		LinuxNamespace{
			typ: 'uts'
		},
		LinuxNamespace{
			typ: 'cgroup'
		},
		LinuxNamespace{
			typ: 'mount'
		},
	]
}

fn create_default_mounts() []Mount {
	return [
		Mount{
			destination: '/proc'
			typ:         'proc'
			source:      'proc'
		},
		Mount{
			destination: '/dev'
			typ:         'tmpfs'
			source:      'tmpfs'
			options:     ['nosuid', 'strictatime', 'mode=755', 'size=65536k']
		},
		Mount{
			destination: '/dev/pts'
			typ:         'devpts'
			source:      'devpts'
			options:     ['nosuid', 'noexec', 'newinstance', 'ptmxmode=0666', 'mode=0620', 'gid=5']
		},
		Mount{
			destination: '/dev/shm'
			typ:         'tmpfs'
			source:      'shm'
			options:     ['nosuid', 'noexec', 'nodev', 'mode=1777', 'size=65536k']
		},
		Mount{
			destination: '/dev/mqueue'
			typ:         'mqueue'
			source:      'mqueue'
			options:     ['nosuid', 'noexec', 'nodev']
		},
		Mount{
			destination: '/sys'
			typ:         'sysfs'
			source:      'sysfs'
			options:     ['nosuid', 'noexec', 'nodev', 'ro']
		},
		Mount{
			destination: '/sys/fs/cgroup'
			typ:         'cgroup'
			source:      'cgroup'
			options:     ['nosuid', 'noexec', 'nodev', 'relatime', 'ro']
		},
	]
}
