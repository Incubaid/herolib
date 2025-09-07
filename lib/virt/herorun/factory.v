module herorun

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.tmux
import time
import freeflowuniverse.herolib.builder

// Container struct and related functionality
pub struct ContainerFactory {
pub mut:
	tmux_session string //this is the name for tmux session if we will use it
}

@[params]
pub struct FactoryInitArgs {
pub:
	reset bool
}	

pub fn new(args FactoryInitArgs) !ContainerFactory {
	mut f:= ContainerFactory{}
	f.init(args)!
	return f
}
fn (self ContainerFactory) init(args ContainerFactoryInitArgs) ! {
    // Alpine (as before)
    alpine_ver := '3.20.3'
    alpine_file := 'alpine-minirootfs-${alpine_ver}-x86_64.tar.gz'
    alpine_url := 'https://dl-cdn.alpinelinux.org/alpine/v${alpine_ver[..4]}/releases/x86_64/${alpine_file}'
    alpine_dest := '/containers/images/alpine/${alpine_file}'
    alpine_rootfs := '/containers/images/alpine/rootfs'
    osal.download(
        url: alpine_url
        dest: alpine_dest
        reset: args.reset
        minsize_kb: 1024
        expand_dir: alpine_rootfs
    )!
    console.print_green('Alpine ${alpine_ver} rootfs prepared at ${alpine_rootfs}')

    // Ubuntu versions with proper codename paths
    ubuntu_info := [
        {ver: '24.04', codename: 'noble'},
        {ver: '25.04', codename: 'plucky'}
    ]

    for info in ubuntu_info {
        file := 'ubuntu-${info.ver}-minimal-cloudimg-amd64-root.tar.xz'
        url := 'https://cloud-images.ubuntu.com/minimal/releases/${info.codename}/release/${file}'
        // Use us.cloud-images domain for 25.04 daily if needed
        if info.ver == '25.04' {
            url = 'https://us.cloud-images.ubuntu.com/daily/server/server/minimal/releases/${info.codename}/release/${file}'
        }
        dest := '/containers/images/ubuntu/${info.ver}/${file}'
        rootfs := '/containers/images/ubuntu/${info.ver}/rootfs'

        osal.download(
            url: url
            dest: dest
            reset: args.reset
            minsize_kb: 10240
            expand_dir: rootfs
        )!

        console.print_green('Ubuntu ${info.ver} (${info.codename}) rootfs prepared at ${rootfs}')
    }
}

@[params]
pub struct ContainerNewArgs {
pub:
	name string
	reset bool
}	

pub fn (self ContainerFactory) list() ![]Container {
	mut containers := []Container{}
	// Get list of containers using runc
	result := osal.exec(cmd: 'runc list', stdout: true, name: 'list_containers') or { '' }
	lines := result.split_into_lines()
	if lines.len <= 1 {
		return containers // No containers found
	}
	for line in lines[1..] {
		parts := line.split(' ')
		if parts.len > 0 {
			containers << Container{
				name: parts[0]
			}
		}
	}
	return containers
}

pub fn (self ContainerFactory) get(args ContainerNewArgs	) ! {
	//TODO: implement get, give error if not exist

}