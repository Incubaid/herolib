module buildah

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.virt.utils
import json

@[params]
pub struct BuildAHNewArgs {
pub mut:
	herocompile   bool
	reset         bool
	default_image string = 'docker.io/ubuntu:latest'
	install       bool   = true // make sure buildah is installed
}

// Use shared BuildPlatformType from utils
pub type BuildPlatformType = utils.BuildPlatformType

pub struct BuildAHFactory {
pub mut:
	default_image string
	platform      BuildPlatformType
	executor      utils.Executor
}

pub fn new(args BuildAHNewArgs) !BuildAHFactory {
	// Validate default image
	validated_image := utils.validate_image_name(args.default_image) or {
		return utils.new_validation_error('default_image', args.default_image, err.msg())
	}

	mut bahf := BuildAHFactory{
		default_image: validated_image
		executor:      utils.buildah_exec(false)
	}

	if args.reset {
		bahf.reset() or {
			return utils.new_build_error('reset', 'factory', err.code(), err.msg(), err.msg())
		}
	}

	// if args.herocompile {
	// 	bahf.builder = builder.hero_compile()!
	// }
	return bahf
}

@[params]
pub struct BuildAhContainerNewArgs {
pub mut:
	name   string = 'default'
	from   string
	delete bool = true
}

// TODO: implement, missing parts
// TODO: need to supprot a docker builder if we are on osx or windows, so we use the builders functionality as base for executing, not directly osal
pub fn (mut self BuildAHFactory) new(args_ BuildAhContainerNewArgs) !BuildAHContainer {
	mut args := args_
	if args.delete {
		self.delete(args.name)!
	}
	if args.from != '' {
		args.from = self.default_image
	}
	mut c := BuildAHContainer{
		name: args.name
		from: args.from
	}
	return c
}

fn (mut self BuildAHFactory) list() ![]BuildAHContainer {
	result := self.executor.exec(['containers', '--json']) or {
		return utils.new_build_error('list', 'containers', err.code(), err.msg(), err.msg())
	}

	return utils.parse_json_output[BuildAHContainer](result.output) or {
		return utils.new_build_error('list', 'containers', 1, err.msg(), err.msg())
	}
}

// delete all builders
pub fn (mut self BuildAHFactory) reset() ! {
	console.print_debug('remove all buildah containers')
	self.executor.exec(['rm', '-a']) or {
		return utils.new_build_error('reset', 'all', err.code(), err.msg(), err.msg())
	}
}

pub fn (mut self BuildAHFactory) delete(name string) ! {
	if self.exists(name)! {
		console.print_debug('remove ${name}')
		self.executor.exec(['rm', name]) or {
			return utils.new_build_error('delete', name, err.code(), err.msg(), err.msg())
		}
	}
}

pub fn (mut self BuildAHFactory) exists(name string) !bool {
	containers := self.list()!
	for container in containers {
		if container.containername == name {
			return true
		}
	}
	return false
}
