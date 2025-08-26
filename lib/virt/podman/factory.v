module podman

import freeflowuniverse.herolib.osal.core as osal { exec }
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.installers.virt.podman as podman_installer
import freeflowuniverse.herolib.installers.lang.herolib

@[heap]
pub struct PodmanFactory {
pub mut:
	// sshkeys_allowed []string // all keys here have access over ssh into the machine, when ssh enabled
	images     []Image
	containers []Container
	builders   []Builder
	buildpath  string
	// cache           bool = true
	// push            bool
	// platform        []BuildPlatformType // used to build
	// registries      []BAHRegistry    // one or more supported BAHRegistries
	prefix string
}

pub enum BuildPlatformType {
	linux_arm64
	linux_amd64
}

@[params]
pub struct NewArgs {
pub mut:
	install     bool = true
	reset       bool
	herocompile bool
}

pub fn new(args_ NewArgs) !PodmanFactory {
	mut args := args_

	// Support both Linux and macOS
	if !core.is_linux()! && !core.is_osx()! {
		return error('only linux and macOS supported as host for now')
	}

	if args.install {
		mut podman_installer0 := podman_installer.get()!
		podman_installer0.install()!
	}

	if args.herocompile {
		herolib.check()! // will check if install, if not will do
		herolib.hero_compile(reset: true)!
	}

	mut factory := PodmanFactory{}
	factory.init()!
	if args.reset {
		factory.reset_all()!
	}

	return factory
}

fn (mut e PodmanFactory) init() ! {
	if e.buildpath == '' {
		e.buildpath = '/tmp/builder'
		exec(cmd: 'mkdir -p ${e.buildpath}', stdout: false)!
	}
	e.load()!
}

// reload the state from system
pub fn (mut e PodmanFactory) load() ! {
	e.builders_load()!
	e.images_load()!
	e.containers_load()!
}

// reset all images & containers, CAREFUL!
pub fn (mut e PodmanFactory) reset_all() ! {
	e.load()!
	for mut container in e.containers.clone() {
		container.delete()!
	}
	for mut image in e.images.clone() {
		image.delete(true)!
	}
	exec(cmd: 'podman rm -a -f', stdout: false)!
	exec(cmd: 'podman rmi -a -f', stdout: false)!
	e.builders_delete_all()!
	osal.done_reset()!
	// Only check systemctl on Linux
	if core.is_linux()! && core.platform()! == core.PlatformType.arch {
		exec(cmd: 'systemctl status podman.socket', stdout: false)!
	}
	e.load()!
}

// Get free port
pub fn (mut e PodmanFactory) get_free_port() ?int {
	mut used_ports := []int{}
	mut range := []int{}

	for c in e.containers {
		for p in c.forwarded_ports {
			used_ports << p.split(':')[0].int()
		}
	}

	for i in 20000 .. 40000 {
		if i !in used_ports {
			range << i
		}
	}
	// arrays.shuffle<int>(mut range, 0)
	if range.len == 0 {
		return none
	}
	return range[0]
}
