module buildah

import freeflowuniverse.herolib.osal.core as osal
// import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.installers.lang.herolib
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.builder
import freeflowuniverse.herolib.virt.utils
import os
import json

// Use shared container status from utils
pub type ContainerStatus = utils.ContainerStatus

pub struct IPAddress {
pub mut:
	ipv4 string
	ipv6 string
}
// need to fill in what is relevant
@[heap]
pub struct BuildAHContainer {
pub mut:
	id            string
	builder       bool
	imageid       string
	imagename     string
	containername string
	//TODO: not sure all below is needed
	hero_in_container bool //once the hero has been installed this is on, does it once per session
// 	created         time.Time
// 	ssh_enabled     bool // if yes make sure ssh is enabled to the container
// 	ipaddr          IPAddress
// 	forwarded_ports []string
// 	mounts          []ContainerVolume
// 	ssh_port        int // ssh port on node that is used to get ssh
// 	ports           []string
// 	networks        []string
// 	labels          map[string]string       @[str: skip]
// 	status          ContainerStatus
// 	memsize         int // in MB
// 	command         string
}

@[params]
pub struct RunArgs {
pub mut:
	cmd string
	// TODO:/..
}

@[params]
pub struct PackageInstallArgs {
pub mut:
	names string
	// TODO:/..
}

// TODO: mimic osal.package_install('mc,tmux,git,rsync,curl,screen,redis,wget,git-lfs')!

// pub fn (mut self BuildAHContainer) package_install(args PackageInstallArgs) !{
// 	//TODO
// 	names := texttools.to_array(args.names)
// 	//now check which OS, need to make platform function on container level so we know which platform it is
// 	panic("implement")
// }

pub fn (mut self BuildAHContainer) copy(src string, dest string) ! {
	mut executor := utils.buildah_exec(false)
	executor.exec(['copy', self.id, src, dest]) or {
		return utils.new_build_error('copy', self.containername, err.code(), err.msg(), err.msg())
	}
}

pub fn (mut self BuildAHContainer) shell() ! {
	mut executor := utils.buildah_exec(false)
	executor.exec_interactive(['run', '--terminal', '--env', 'TERM=xterm', self.id, '/bin/bash']) or {
		return utils.new_build_error('shell', self.containername, err.code(), err.msg(), err.msg())
	}
}

pub fn (mut self BuildAHContainer) clean() ! {
	cmd := '
		#set -x
		set +e
		rm -rf /root/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/share/doc
		#pacman -Rns $(pacman -Qtdq) --noconfirm
		#pacman -Scc --noconfirm	
		rm -rf /var/lib/pacman/sync/*
		rm -rf /tmp/*
		rm -rf /var/tmp/*
		find /var/log -type f -name "*.log" -exec truncate -s 0 {} \\;
		rm -rf /home/*/.cache/*
		rm -rf /usr/share/doc/*
		rm -rf /usr/share/man/*
		rm -rf /usr/share/info/*
		rm -rf /usr/share/licenses/*
		find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name "en*" -exec rm -rf {} \\;
		rm -rf /usr/share/i18n
		rm -rf /usr/share/icons/*
		rm -rf /usr/lib/modules/*
		rm -rf /var/cache/pacman
		journalctl --vacuum-time=1s	

	'
	self.exec(cmd: cmd, stdout: false)!
}

pub fn (mut self BuildAHContainer) delete() ! {
	mut executor := utils.buildah_exec(false)
	executor.exec(['rm', self.containername]) or {
		return utils.new_build_error('delete', self.containername, err.code(), err.msg(), err.msg())
	}
}

pub fn (mut self BuildAHContainer) inspect() !BuilderInfo {
	cmd := 'buildah inspect ${self.containername}'
	job := self.exec(cmd:(cmd)!
	out:=job.output
	mut r := json.decode(BuilderInfo, out) or {
		return error('Failed to decode JSON for inspect: ${err}')
	}
	return r
}

// mount the build container to a path and return the path where its mounted
pub fn (mut self BuildAHContainer) mount_to_path() !string {
	cmd := 'buildah mount ${self.containername}'
	out := self.exec(cmd:cmd)!
	return out.trim_space()
}

pub fn (mut self BuildAHContainer) commit(image_name string) ! {
	// Validate image name
	validated_name := utils.validate_image_name(image_name) or {
		return utils.new_validation_error('image_name', image_name, err.msg())
	}

	mut executor := utils.buildah_exec(false)
	executor.exec(['commit', self.containername, validated_name]) or {
		return utils.new_build_error('commit', self.containername, err.code(), err.msg(), err.msg())
	}
}

pub fn (self BuildAHContainer) set_entrypoint(entrypoint string) ! {
	mut executor := utils.buildah_exec(false)
	executor.exec(['config', '--entrypoint', entrypoint, self.containername]) or {
		return utils.new_build_error('set_entrypoint', self.containername, err.code(), err.msg(), err.msg())
	}
}

pub fn (self BuildAHContainer) set_workingdir(workdir string) ! {
	mut executor := utils.buildah_exec(false)
	executor.exec(['config', '--workingdir', workdir, self.containername]) or {
		return utils.new_build_error('set_workingdir', self.containername, err.code(), err.msg(), err.msg())
	}
}

pub fn (self BuildAHContainer) set_cmd(command string) ! {
	mut executor := utils.buildah_exec(false)
	executor.exec(['config', '--cmd', command, self.containername]) or {
		return utils.new_build_error('set_cmd', self.containername, err.code(), err.msg(), err.msg())
	}
}
