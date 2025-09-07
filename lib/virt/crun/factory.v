module crun

import freeflowuniverse.herolib.core.texttools

__global (
	crun_configs map[string]&CrunConfig
)

@[params]
pub struct FactoryArgs {
pub mut:
	name string = "default"
}

pub struct CrunConfig {
pub mut:
	name string
	spec Spec

}

// Process configuration
pub fn (mut config CrunConfig) set_command(args []string) &CrunConfig {
	config.spec.process.args = args
	return config
}

pub fn (mut config CrunConfig) set_working_dir(cwd string) &CrunConfig {
	config.spec.process.cwd = cwd
	return config
}

pub fn (mut config CrunConfig) set_user(uid u32, gid u32, additional_gids []u32) &CrunConfig {
	config.spec.process.user = User{
		uid: uid
		gid: gid
		additional_gids: additional_gids
	}
	return config
}

pub fn (mut config CrunConfig) add_env(key string, value string) &CrunConfig {
	config.spec.process.env << '${key}=${value}'
	return config
}

// Root filesystem configuration
pub fn (mut config CrunConfig) set_rootfs(path string, readonly bool) &CrunConfig {
	config.spec.root = Root{
		path: path
		readonly: readonly
	}
	return config
}

// Hostname
pub fn (mut config CrunConfig) set_hostname(hostname string) &CrunConfig {
	config.spec.hostname = hostname
	return config
}

// Resource limits
pub fn (mut config CrunConfig) set_memory_limit(limit_bytes u64) &CrunConfig {
	config.spec.linux.resources.memory_limit = limit_bytes
	return config
}

pub fn (mut config CrunConfig) set_cpu_limits(period u64, quota i64, shares u64) &CrunConfig {
	config.spec.linux.resources.cpu_period = period
	config.spec.linux.resources.cpu_quota = quota
	config.spec.linux.resources.cpu_shares = shares
	return config
}

// Add mount
pub fn (mut config CrunConfig) add_mount(destination string, source string, typ MountType, options []MountOption) &CrunConfig {
	config.spec.mounts << Mount{
		destination: destination
		typ: typ
		source: source
		options: options
	}
	return config
}

// Add capability
pub fn (mut config CrunConfig) add_capability(cap Capability) &CrunConfig {
	if cap !in config.spec.process.capabilities.bounding {
		config.spec.process.capabilities.bounding << cap
	}
	if cap !in config.spec.process.capabilities.effective {
		config.spec.process.capabilities.effective << cap
	}
	if cap !in config.spec.process.capabilities.permitted {
		config.spec.process.capabilities.permitted << cap
	}
	return config
}

// Remove capability
pub fn (mut config CrunConfig) remove_capability(cap Capability) &CrunConfig {
	config.spec.process.capabilities.bounding = config.spec.process.capabilities.bounding.filter(it != cap)
	config.spec.process.capabilities.effective = config.spec.process.capabilities.effective.filter(it != cap)
	config.spec.process.capabilities.permitted = config.spec.process.capabilities.permitted.filter(it != cap)
	return config
}
}

pub fn new(args FactoryArgs) !&CrunConfig {
	name := texttools.name_fix(args.name)
	
	// Create default spec
	default_spec := create_default_spec()
	
	mut config := &CrunConfig{
		name: name
		spec: default_spec
	}
	
	crun_configs[name] = config
	return config
}

pub fn get(args FactoryArgs) !&CrunConfig {
	name := texttools.name_fix(args.name)
	return crun_configs[name] or {
		return error('crun config with name "${name}" does not exist')
	}
}

fn create_default_spec() Spec {
	return Spec{
		version: '1.0.0'
		platform: Platform{
			os: .linux
			arch: .amd64
		}
		process: Process{
			terminal: true
			user: User{
				uid: 0
				gid: 0
				additional_gids: []
			}
			args: ['/bin/sh']
			env: ['PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin']
			cwd: '/'
			capabilities: Capabilities{
				bounding: [.cap_chown, .cap_dac_override, .cap_fsetid, .cap_fowner, .cap_mknod, .cap_net_raw, .cap_setgid, .cap_setuid, .cap_setfcap, .cap_setpcap, .cap_net_bind_service, .cap_sys_chroot, .cap_kill, .cap_audit_write]
				effective: [.cap_chown, .cap_dac_override, .cap_fsetid, .cap_fowner, .cap_mknod, .cap_net_raw, .cap_setgid, .cap_setuid, .cap_setfcap, .cap_setpcap, .cap_net_bind_service, .cap_sys_chroot, .cap_kill, .cap_audit_write]
				inheritable: []
				permitted: [.cap_chown, .cap_dac_override, .cap_fsetid, .cap_fowner, .cap_mknod, .cap_net_raw, .cap_setgid, .cap_setuid, .cap_setfcap, .cap_setpcap, .cap_net_bind_service, .cap_sys_chroot, .cap_kill, .cap_audit_write]
				ambient: []
			}
			rlimits: []
		}
		root: Root{
			path: 'rootfs'
			readonly: false
		}
		hostname: 'container'
		mounts: create_default_mounts()
		linux: Linux{
			namespaces: create_default_namespaces()
			resources: LinuxResource{}
			devices: []
		}
		hooks: Hooks{}
	}
}

fn create_default_namespaces() []LinuxNamespace {
	return [
		LinuxNamespace{typ: 'pid', path: ''},
		LinuxNamespace{typ: 'network', path: ''},
		LinuxNamespace{typ: 'ipc', path: ''},
		LinuxNamespace{typ: 'uts', path: ''},
		LinuxNamespace{typ: 'mount', path: ''},
	]
}

fn create_default_mounts() []Mount {
	return [
		Mount{
			destination: '/proc'
			typ: .proc
			source: 'proc'
			options: [.nosuid, .noexec, .nodev]
		},
		Mount{
			destination: '/dev'
			typ: .tmpfs
			source: 'tmpfs'
			options: [.nosuid]
		},
		Mount{
			destination: '/sys'
			typ: .sysfs
			source: 'sysfs'
			options: [.nosuid, .noexec, .nodev, .ro]
		},
	]
}