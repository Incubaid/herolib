module podman

import time
import incubaid.herolib.osal.core as osal { exec }
import incubaid.herolib.ui.console
import json

// BuildError represents errors that occur during build operations
pub struct BuildError {
	Error
pub:
	operation string
	container string
	exit_code int
	message   string
	stderr    string
}

pub fn (err BuildError) msg() string {
	return 'Build operation failed: ${err.operation}\nContainer: ${err.container}\nMessage: ${err.message}\nStderr: ${err.stderr}'
}

pub fn (err BuildError) code() int {
	return err.exit_code
}

@[heap]
pub struct Builder {
pub mut:
	id            string
	containername string
	imageid       string
	imagename     string
	created       time.Time
	engine        &PodmanFactory @[skip; str: skip]
}

pub struct BuilderInfo {
pub:
	id            string
	containername string
	imageid       string
	imagename     string
	created       string
}

// load all buildah containers/builders
pub fn (mut self PodmanFactory) builders_load() ! {
	self.builders = []Builder{}
	cmd := 'buildah containers --json'
	out := osal.execute_silent(cmd) or {
		// If buildah is not installed or no containers, return empty list
		console.print_debug('buildah containers command failed: ${err}')
		return
	}

	if out.trim_space() == '' || out.trim_space() == '[]' {
		return
	}

	mut r := json.decode([]BuilderInfo, out) or {
		console.print_debug('Failed to decode buildah JSON: ${err}')
		return
	}

	for item in r {
		mut builder := Builder{
			engine:        &self
			id:            item.id
			containername: item.containername
			imageid:       item.imageid
			imagename:     item.imagename
		}
		// Parse created time if needed
		builder.created = time.now() // TODO: parse from item.created
		self.builders << builder
	}
}

// delete all buildah containers/builders
pub fn (mut self PodmanFactory) builders_delete_all() ! {
	for mut builder in self.builders.clone() {
		builder.delete()!
	}
	self.builders = []Builder{}
}

@[params]
pub struct BuilderNewArgs {
pub mut:
	name   string = 'default'
	from   string = 'docker.io/ubuntu:latest'
	delete bool   = true
}

pub fn (mut e PodmanFactory) builder_new(args_ BuilderNewArgs) !Builder {
	mut args := args_
	if args.delete {
		e.builder_delete(args.name)!
	}
	exec(cmd: 'buildah --name ${args.name} from ${args.from}')!
	e.builders_load()!
	return e.builder_get(args.name)!
}

// get buildah containers
pub fn (mut e PodmanFactory) builders_get() ![]Builder {
	if e.builders.len == 0 {
		e.builders_load()!
	}
	return e.builders
}

pub fn (mut e PodmanFactory) builder_exists(name string) !bool {
	r := e.builders_get()!
	res := r.filter(it.containername == name)
	if res.len == 1 {
		return true
	}
	if res.len > 1 {
		panic('bug: multiple builders with same name')
	}
	return false
}

pub fn (mut e PodmanFactory) builder_get(name string) !Builder {
	r := e.builders_get()!
	res := r.filter(it.containername == name)
	if res.len == 0 {
		return error('builder with name ${name} not found')
	}
	if res.len > 1 {
		return error('multiple builders found with name ${name}')
	}
	return res[0]
}

pub fn (mut e PodmanFactory) builder_delete(name string) ! {
	if e.builder_exists(name)! {
		exec(cmd: 'buildah rm ${name}', stdout: false) or {
			console.print_debug('Failed to delete builder ${name}: ${err}')
		}
	}
	e.builders_load()!
}

// Builder methods
pub fn (mut self Builder) delete() ! {
	self.engine.builder_delete(self.containername)!
}

pub fn (mut self Builder) run(cmd string) ! {
	cmd_str := 'buildah run ${self.id} ${cmd}'
	exec(cmd: cmd_str)!
}

pub fn (mut self Builder) copy(src string, dest string) ! {
	cmd := 'buildah copy ${self.id} ${src} ${dest}'
	exec(cmd: cmd, stdout: false)!
}

pub fn (mut self Builder) shell() ! {
	cmd := 'buildah run --terminal --env TERM=xterm ${self.id} /bin/bash'
	osal.execute_interactive(cmd)!
}

pub fn (mut self Builder) commit(image_name string) ! {
	// Commit the buildah container to an image
	cmd := 'buildah commit ${self.containername} ${image_name}'
	exec(cmd: cmd, stdout: false) or {
		return BuildError{
			operation: 'commit'
			container: self.containername
			exit_code: 1
			message:   'Failed to commit buildah container to image'
			stderr:    err.msg()
		}
	}

	// Automatically transfer to podman for seamless integration
	// Transfer image from buildah to podman using buildah push
	transfer_cmd := 'buildah push ${image_name} containers-storage:${image_name}'
	exec(cmd: transfer_cmd, stdout: false) or {
		console.print_debug('Warning: Failed to transfer image to podman: ${err}')
		console.print_debug('Image is available in buildah but may need manual transfer')
		console.print_debug('You can manually transfer with: buildah push ${image_name} containers-storage:${image_name}')
		// Don't fail the commit if transfer fails
	}
}

pub fn (self Builder) set_entrypoint(entrypoint string) ! {
	cmd := 'buildah config --entrypoint \'${entrypoint}\' ${self.containername}'
	exec(cmd: cmd)!
}

pub fn (self Builder) set_workingdir(workdir string) ! {
	cmd := 'buildah config --workingdir ${workdir} ${self.containername}'
	exec(cmd: cmd)!
}

pub fn (self Builder) set_cmd(command string) ! {
	cmd := 'buildah config --cmd ${command} ${self.containername}'
	exec(cmd: cmd)!
}

// mount the build container to a path and return the path where its mounted
pub fn (mut self Builder) mount_to_path() !string {
	cmd := 'buildah mount ${self.containername}'
	out := osal.execute_silent(cmd)!
	return out.trim_space()
}

// Builder solution methods for common setups
@[params]
pub struct GetArgs {
pub mut:
	reset bool
}

// builder machine based on arch and install vlang
pub fn (mut e PodmanFactory) builder_base(args GetArgs) !Builder {
	name := 'base'
	if !args.reset && e.builder_exists(name)! {
		return e.builder_get(name)!
	}
	console.print_header('buildah base build')

	mut builder := e.builder_new(name: name, from: 'scratch', delete: true)!
	mount_path := builder.mount_to_path()!
	if mount_path.len < 4 {
		return error('mount_path needs to be +4 chars')
	}

	// TODO: Add base system setup here
	console.print_header('buildah base build done')
	return builder
}

// builder with hero tools
pub fn (mut e PodmanFactory) builder_hero(args GetArgs) !Builder {
	name := 'hero'
	if !args.reset && e.builder_exists(name)! {
		return e.builder_get(name)!
	}
	console.print_header('buildah hero build')

	mut builder := e.builder_new(name: name, from: 'docker.io/ubuntu:latest', delete: true)!

	// Install basic tools and hero
	builder.run('apt-get update && apt-get install -y curl git build-essential')!
	// TODO: Add hero installation steps

	console.print_header('buildah hero build done')
	return builder
}
