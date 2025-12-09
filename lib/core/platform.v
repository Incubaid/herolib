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
	fedora
}

pub fn platform_enum_from_string(platform string) PlatformType {
	return match platform.to_lower() {
		'osx' { .osx }
		'ubuntu' { .ubuntu }
		'alpine' { .alpine }
		'arch' { .arch }
		'suse' { .suse }
		'fedora' { .fedora }
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
	} else if cmd_exists('dnf') {
		platform_ = PlatformType.fedora
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
		|| platform()! == .alpine || platform()! == .fedora
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


// Detect if we are running inside a container (Docker, Kubernetes, CI, GitHub Actions)
pub fn is_container() bool {
    // Cache if already computed
    cached := memdb_get('is_container')
    if cached != '' {
        return cached == 'true'
    }

    mut result := false

    // 1. Docker / Podman indicator file
    if os.exists('/.dockerenv') {
        result = true
    }

    // 2. Check cgroup info for container markers
    if !result {
        if os.exists('/proc/1/cgroup') {
            cg := os.read_file('/proc/1/cgroup') or { '' }
            if cg.contains('docker')
                || cg.contains('kubepods')
                || cg.contains('containerd')
                || cg.contains('podman')
                || cg.contains('machine.slice') {
                result = true
            }
        }
    }

	if in_runner() {
		result = true
	}

    // Store result
    memdb_set('is_container', if result { 'true' } else { 'false' })

    return result
}



// detect if in a  runner environment
pub fn in_runner() bool {
    // Cache if already computed
    cached := memdb_get('in_runner')
    if cached != '' {
        return cached == 'true'
    }

    mut result := false

    // 3. Environment variables used by CI/container systems
    envs := {
        'GITHUB_ACTIONS':        true,
        'CI':                    true,
        'container':             true,
        'KUBERNETES_SERVICE_HOST': true,
    }

    for k, _ in envs {
        if os.getenv(k) != '' {
            result = true
            break
        }
    }

    // Store result
    memdb_set('in_runner', if result { 'true' } else { 'false' })

    return result
}

