module crun

// OCI Runtime Spec structures that can be directly encoded to JSON
pub struct Spec {
pub mut:
	oci_version  string @[json: 'ociVersion']
	platform     Platform
	process      Process
	root         Root
	hostname     string
	mounts       []Mount
	linux_config LinuxConfig
	hooks        Hooks
}

pub struct Platform {
pub mut:
	os   string = 'linux'
	arch string = 'amd64'
}

pub struct Process {
pub mut:
	terminal          bool = true
	user              User
	args              []string
	env               []string
	cwd               string = '/'
	capabilities      Capabilities
	rlimits           []Rlimit
	no_new_privileges bool @[json: 'noNewPrivileges']
}

pub struct User {
pub mut:
	uid             u32
	gid             u32
	additional_gids []u32 @[json: 'additionalGids']
}

pub struct Capabilities {
pub mut:
	bounding    []string
	effective   []string
	inheritable []string
	permitted   []string
	ambient     []string
}

pub struct Rlimit {
pub mut:
	typ  string @[json: 'type']
	hard u64
	soft u64
}

pub struct Root {
pub mut:
	path     string
	readonly bool
}

pub struct Mount {
pub mut:
	destination string
	typ         string @[json: 'type']
	source      string
	options     []string
}

pub struct LinuxConfig {
pub mut:
	namespaces     []LinuxNamespace
	resources      LinuxResources
	devices        []LinuxDevice
	masked_paths   []string         @[json: 'maskedPaths']
	readonly_paths []string         @[json: 'readonlyPaths']
	uid_mappings   []LinuxIDMapping @[json: 'uidMappings']
	gid_mappings   []LinuxIDMapping @[json: 'gidMappings']
}

pub struct LinuxNamespace {
pub mut:
	typ  string @[json: 'type']
	path string @[omitempty]
}

pub struct LinuxResources {
pub mut:
	memory Memory
	cpu    CPU
	pids   Pids
	blkio  BlockIO
}

pub struct Memory {
pub mut:
	limit       u64 @[omitempty]
	reservation u64 @[omitempty]
	swap        u64 @[omitempty]
	kernel      u64 @[omitempty]
	swappiness  i64 @[omitempty]
}

pub struct CPU {
pub mut:
	shares u64    @[omitempty]
	quota  i64    @[omitempty]
	period u64    @[omitempty]
	cpus   string @[omitempty]
	mems   string @[omitempty]
}

pub struct Pids {
pub mut:
	limit i64 @[omitempty]
}

pub struct BlockIO {
pub mut:
	weight u16 @[omitempty]
}

pub struct LinuxDevice {
pub mut:
	path      string
	typ       string @[json: 'type']
	major     i64
	minor     i64
	file_mode u32 @[json: 'fileMode']
	uid       u32
	gid       u32
}

pub struct LinuxIDMapping {
pub mut:
	container_id u32 @[json: 'containerID']
	host_id      u32 @[json: 'hostID']
	size         u32
}

pub struct Hooks {
pub mut:
	prestart  []Hook
	poststart []Hook
	poststop  []Hook
}

pub struct Hook {
pub mut:
	path string
	args []string
	env  []string
}

// Enums for type safety but convert to strings
pub enum MountType {
	bind
	tmpfs
	proc
	sysfs
	devpts
	mqueue
	cgroup
	nfs
	overlay
}

pub enum MountOption {
	rw
	ro
	noexec
	nosuid
	nodev
	rbind
	relatime
	strictatime
	mode
	size
}

pub enum Capability {
	cap_chown
	cap_dac_override
	cap_dac_read_search
	cap_fowner
	cap_fsetid
	cap_kill
	cap_setgid
	cap_setuid
	cap_setpcap
	cap_linux_immutable
	cap_net_bind_service
	cap_net_broadcast
	cap_net_admin
	cap_net_raw
	cap_ipc_lock
	cap_ipc_owner
	cap_sys_module
	cap_sys_rawio
	cap_sys_chroot
	cap_sys_ptrace
	cap_sys_pacct
	cap_sys_admin
	cap_sys_boot
	cap_sys_nice
	cap_sys_resource
	cap_sys_time
	cap_sys_tty_config
	cap_mknod
	cap_lease
	cap_audit_write
	cap_audit_control
	cap_setfcap
	cap_mac_override
	cap_mac_admin
	cap_syslog
	cap_wake_alarm
	cap_block_suspend
	cap_audit_read
}

pub enum RlimitType {
	rlimit_cpu
	rlimit_fsize
	rlimit_data
	rlimit_stack
	rlimit_core
	rlimit_rss
	rlimit_nproc
	rlimit_nofile
	rlimit_memlock
	rlimit_as
	rlimit_lock
	rlimit_sigpending
	rlimit_msgqueue
	rlimit_nice
	rlimit_rtprio
	rlimit_rttime
}
