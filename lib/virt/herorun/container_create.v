module herorun

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.tmux
import freeflowuniverse.herolib.osal.core as osal
import time
import freeflowuniverse.herolib.builder
import json





pub enum ContainerImage {
	alpine_3_20
	ubuntu_24_04
	ubuntu_25_04
}



@[params]
pub struct ContainerNewArgs {
pub:
	name string @[required]
	image ContainerImage = .alpine_3_20
	reset bool
}

pub fn (mut self ContainerFactory) new(args ContainerNewArgs) !&Container {
	if args.name in self.containers && !args.reset {
		return self.containers[args.name]
	}
	
	// Create container config
	self.create_container_config(args)!
	
	// Create container using crun
	osal.exec(cmd: 'crun create --bundle /containers/configs/${args.name} ${args.name}', stdout: true)!
	
	mut container := &Container{
		name: args.name
		factory: &self
	}
	
	self.containers[args.name] = container
	return container
}


fn (self ContainerFactory) create_container_config(args ContainerNewArgs) ! {
	// Determine rootfs path based on image
	mut rootfs_path := ''
	match args.image {
		.alpine_3_20 {
			rootfs_path = '/containers/images/alpine/rootfs'
		}
		.ubuntu_24_04 {
			rootfs_path = '/containers/images/ubuntu/24.04/rootfs'
		}
		.ubuntu_25_04 {
			rootfs_path = '/containers/images/ubuntu/25.04/rootfs'
		}
	}
	
	config_dir := '/containers/configs/${args.name}'
	osal.exec(cmd: 'mkdir -p ${config_dir}', stdout: false)!
	
	// Generate OCI config.json
	config_content := $tmpl('config_template.json')
	config_path := '${config_dir}/config.json'
	
	mut p := pathlib.get_file(path: config_path, create: true)!
	p.write(config_content)!
}