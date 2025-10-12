module core

import os

// import incubaid.herolib.ui.console
// Returns the enum value that matches the provided string for PlatformType

pub enum PlatformType {
	unknown
	osx
	ubuntu
	alpine
	arch
	suse
}

pub fn platform_enum_from_string(platform string) PlatformType {
	return match platform.to_lower() {
		'osx' { .osx }
		'ubuntu' { .ubuntu }
		'alpine' { .alpine }
		'arch' { .arch }
		else { .unknown }
	}
}

// Returns the enum value that matches the provided string for CPUType
pub fn cputype_enum_from_string(cputype string) CPUType {
	return match cputype.to_lower() {
		'intel' { .intel }
		'arm' { .arm }
		'intel32' { .intel32 }
		'arm32' { .arm32 }
		else { .unknown }
	}
}

pub enum CPUType {
	unknown
	intel
	arm
	intel32
	arm32
}

pub fn cmd_exists(cmd string) bool {
	cmd1 := 'which ${cmd}'
	res := os.execute(cmd1)
	if res.exit_code > 0 {
		return false
	}
	return true
}

pub fn platform() !PlatformType {
	mut platform_ := PlatformType.unknown
	platform_ = platform_enum_from_string(memdb_get('platformtype'))
	if platform_ != PlatformType.unknown {
		return platform_
	}
	if cmd_exists('sw_vers') {
		platform_ = PlatformType.osx
	} else if cmd_exists('apt-get') {
		platform_ = PlatformType.ubuntu
	} else if cmd_exists('apk') {
		platform_ = PlatformType.alpine
	} else if cmd_exists('pacman') {
		platform_ = PlatformType.arch
	} else {
		return error('Unknown platform')
	}
	if platform_ != PlatformType.unknown {
		memdb_set('platformtype', platform_.str())
	}
	return platform_
}

pub fn cputype() !CPUType {
	mut cputype_ := CPUType.unknown
	cputype_ = cputype_enum_from_string(memdb_get('cputype'))
	if cputype_ != CPUType.unknown {
		return cputype_
	}
	res := os.execute('uname -m')
	if res.exit_code > 0 {
		return error("can't execute uname -m")
	}
	sys_info := res.output

	cputype_ = match sys_info.to_lower().trim_space() {
		'x86_64' {
			CPUType.intel
		}
		'arm64' {
			CPUType.arm
		}
		'aarch64' {
			CPUType.arm
		}
		else {
			CPUType.unknown
		}
	}

	if cputype_ != CPUType.unknown {
		memdb_set('cputype', cputype_.str())
	}
	return cputype_
}

pub fn is_osx() !bool {
	return platform()! == .osx
}

pub fn is_osx_arm() !bool {
	return platform()! == .osx && cputype()! == .arm
}

pub fn is_osx_intel() !bool {
	return platform()! == .osx && cputype()! == .intel
}

pub fn is_ubuntu() !bool {
	return platform()! == .ubuntu
}

pub fn is_linux() !bool {
	return platform()! == .ubuntu || platform()! == .arch || platform()! == .suse
		|| platform()! == .alpine
}

pub fn is_linux_arm() !bool {
	// console.print_debug("islinux:${is_linux()!} cputype:${cputype()!}")
	return is_linux()! && cputype()! == .arm
}

pub fn is_linux_intel() !bool {
	return is_linux()! && cputype()! == .intel
}

pub fn hostname() !string {
	res := os.execute('hostname')
	if res.exit_code > 0 {
		return error("can't get hostname. Error.")
	}
	return res.output.trim_space()
}

// e.g. systemd, bash, zinit
pub fn initname() !string {
	res := os.execute('ps -p 1 -o comm=')
	if res.exit_code > 0 {
		return error("can't get process with pid 1. Error:\n${res.output}")
	}
	return res.output.trim_space()
}
