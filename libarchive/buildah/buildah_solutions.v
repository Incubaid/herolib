module buildah

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import os

@[params]
pub struct GetArgs {
pub mut:
	reset bool
}

// builder machine based on arch and install vlang
// TODO need to change, go to ubuntu
pub fn builder_base(args GetArgs) !BuildAHContainer {
	name := 'base'
	console.print_header('buildah base build')

	mut builder := e.builder_new(name: name, from: 'scratch', delete: true)!
	mount_path := builder.mount_to_path()!
	if mount_path.len < 4 {
		return error('mount_path needs to be +4 chars')
	}
	self.exec(
		cmd: '

			export MOUNT_PATH=\'${mount_path}\'

			mmdebstrap --variant=minbase --components="main,universe" --include="apt,base-files,base-passwd,bash,coreutils" noble \${MOUNT_PATH}

			echo "Binding essential directories..."
			mount --bind /dev "\${MOUNT_PATH}/dev"
			mount --bind /proc "\${MOUNT_PATH}/proc"
			mount --bind /sys "\${MOUNT_PATH}/sys"

			echo "tzdata tzdata/Areas select Europe" | chroot "\${MOUNT_PATH}" debconf-set-selections
			echo "tzdata tzdata/Zones/Europe select Brussels" | chroot "\${MOUNT_PATH}" debconf-set-selections

			chroot \${MOUNT_PATH} apt update

			# Set up APT for non-interactive installation
			export DEBIAN_FRONTEND=noninteractive
			export DEBCONF_NONINTERACTIVE_SEEN=true

			# Update package lists
			echo "Updating package lists in chroot..."
			chroot \${MOUNT_PATH} apt-get update -yq

			# Install required packages
			echo "Installing essential packages..."
			chroot \${MOUNT_PATH} apt-get install -yq screen bash coreutils curl mc unzip sudo which openssh-client openssh-server redis wget

			echo "Cleaning up..."
			umount "\${MOUNT_PATH}/dev" || true
			umount "\${MOUNT_PATH}/proc" || true
			umount "\${MOUNT_PATH}/sys" || true

			'
	)!
	builder.install_zinit()!
	// builder.set_entrypoint('redis-server')!
	builder.commit('localhost/${name}')!
	return builder
}

// TODO: all below are not good, need to use play cmd over hero remotely. see how we did it with core_installers

// // builder machine based on arch and install vlang
// pub fn (mut e CEngine) builder_go_rust(args GetArgs) !BuildAHContainer {
// 	console.print_header('buildah builder go rust')
// 	name := 'builder_go_rust'
// 	e.builder_base(reset: false)!
// 	if !args.reset && e.builder_exists(name)! {
// 		return e.builder_get(name)!
// 	}
// 	mut builder := e.builder_new(name: name, from: 'localhost/base', delete: true)!
// 	builder.hero_execute_cmd('installers -n golang,rust')!
// 	// builder.clean()!
// 	builder.commit('localhost/${name}')!
// 	e.load()!
// 	return builder
// }

// pub fn (mut e CEngine) builder_js(args GetArgs) !BuildAHContainer {
// 	console.print_header('buildah builder js')
// 	name := 'builder_js'
// 	e.builder_base(reset: false)!
// 	if !args.reset && e.builder_exists(name)! {
// 		return e.builder_get(name)!
// 	}
// 	mut builder := e.builder_new(name: name, from: 'localhost/base', delete: true)!
// 	builder.hero_execute_cmd('installers -n nodejs')!
// 	// builder.clean()!
// 	builder.commit('localhost/${name}')!
// 	e.load()!
// 	return builder
// }

// pub fn (mut e CEngine) builder_js_python(args GetArgs) !BuildAHContainer {
// 	console.print_header('buildah builder js python')
// 	name := 'builder_js_python'
// 	e.builder_js(reset: false)!
// 	if !args.reset && e.builder_exists(name)! {
// 		return e.builder_get(name)!
// 	}
// 	mut builder := e.builder_new(name: name, from: 'localhost/builder_js', delete: true)!
// 	builder.hero_execute_cmd('installers -n python')!
// 	// builder.clean()!
// 	builder.commit('localhost/${name}')!
// 	e.load()!
// 	return builder
// }

// pub fn (mut e CEngine) builder_hero(args GetArgs) !BuildAHContainer {
// 	console.print_header('buildah builder hero dev')
// 	name := 'builder_hero'
// 	e.builder_js_python(reset: false)!
// 	if !args.reset && e.builder_exists(name)! {
// 		return e.builder_get(name)!
// 	}
// 	mut builder := e.builder_new(name: name, from: 'localhost/builder_js_python', delete: true)!
// 	builder.hero_execute_cmd('installers -n hero')!
// 	// builder.clean()!
// 	builder.commit('localhost/${name}')!
// 	e.load()!
// 	return builder
// }

// pub fn (mut e CEngine) builder_herodev(args GetArgs) !BuildAHContainer {
// 	console.print_header('buildah builder hero dev')
// 	name := 'builder_herodev'
// 	e.builder_js_python(reset: false)!
// 	if !args.reset && e.builder_exists(name)! {
// 		return e.builder_get(name)!
// 	}
// 	mut builder := e.builder_new(name: name, from: 'localhost/builder_hero', delete: true)!
// 	builder.hero_execute_cmd('installers -n herodev')!
// 	// builder.clean()!
// 	builder.commit('localhost/${name}')!
// 	e.load()!
// 	return builder
// }

// pub fn (mut e CEngine) builder_heroweb(args GetArgs) !BuildAHContainer {
// 	console.print_header('buildah builder hero web')
// 	name := 'builder_heroweb'
// 	e.builder_go_rust(reset: false)!
// 	e.builder_hero(reset: false)!
// 	if !args.reset && e.builder_exists(name)! {
// 		return e.builder_get(name)!
// 	}
// 	mut builder0 := e.builder_new(
// 		name:   'builder_heroweb_temp'
// 		from:   'localhost/builder_go_rust'
// 		delete: true
// 	)!
// 	builder0.hero_execute_cmd('installers -n heroweb')!
// 	// builder0.hero_execute_cmd("installers -n heroweb")!
// 	mpath := builder0.mount_to_path()!

// 	// copy the built binary to host
// 	self.exec(
// 		cmd: '
// 		mkdir -p  ${os.home_dir()}/hero/var/bin
// 		cp ${mpath}/usr/local/bin/* ${os.home_dir()}/hero/var/bin/
// 	'
// 	)!

// 	builder0.delete()!
// 	mut builder2 := e.builder_new(name: name, from: 'localhost/builder_hero', delete: true)!
// 	builder2.copy('${os.home_dir()}/hero/var/bin/', '/usr/local/bin/')!
// 	builder2.commit('localhost/${name}')!
// 	e.load()!
// 	return builder2
// }
