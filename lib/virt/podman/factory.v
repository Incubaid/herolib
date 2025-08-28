module herocontainers

import freeflowuniverse.herolib.osal.core as osal { exec }
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.installers.virt.podman as podman_installer

@[heap]
pub struct PodmanFactory {
pub mut:
	// sshkeys_allowed []string // all keys here have access over ssh into the machine, when ssh enabled
	images          []Image
	containers      []Container
	buildpath       string
	// cache           bool = true
	// push            bool
	// platform        []BuildPlatformType // used to build
	// registries      []BAHRegistry    // one or more supported BAHRegistries
	prefix string
}


@[params]
pub struct NewArgs {
pub mut:
	install     bool = true
	reset       bool
	herocompile bool
}


	if args.install {
		mut podman_installer0 := podman_installer.get()!
		podman_installer0.install()!
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
	if core.platform()! == core.PlatformType.arch {
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
