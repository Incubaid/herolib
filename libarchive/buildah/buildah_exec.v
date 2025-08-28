module buildah

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.pathlib
import os

@[params]
pub struct Command {
pub mut:
	name               string // to give a name to your command, good to see logs...
	cmd                string
	description        string
	timeout            int  = 3600 // timeout in sec
	stdout             bool = true
	stdout_log         bool = true
	raise_error        bool = true // if false, will not raise an error but still error report
	ignore_error       bool              // means if error will just exit and not raise, there will be no error reporting
	work_folder        string            // location where cmd will be executed
	environment        map[string]string // env variables
	ignore_error_codes []int
	scriptpath         string // is the path where the script will be put which is executed
	scriptkeep         bool   // means we don't remove the script
	debug              bool   // if debug will put +ex in the script which is being executed and will make sure script stays
	shell              bool   // means we will execute it in a shell interactive
	retry              int
	interactive        bool = true
	async              bool
	runtime            osal.RunTime
}

pub enum RunTime {
	bash
	python
	heroscript
	herocmd
	v
}

// should use builders underneith
pub fn (mut self BuildAHContainer) exec(cmd Command) !osal.Job {
	// make sure we have hero in the hostnode of self
	self.hero_copy()!

	mut rt := RunTime.bash

	scriptpath := osal.cmd_to_script_path(cmd: cmd.cmd, runtime: cmd.runtime)!

	if cmd.runtime == .heroscript || cmd.runtime == .herocmd {
		self.hero_copy()!
	}

	script_basename := os.base(scriptpath)
	script_path_in_container := '/tmp/${script_basename}'

	self.copy(scriptpath, script_path_in_container)!
	// console.print_debug("copy ${scriptpath} into container '${self.containername}'")
	cmd_str := 'buildah run ${self.id} ${script_path_in_container}'
	// console.print_debug(cmd_str)

	if cmd.runtime == .heroscript || cmd.runtime == .herocmd {
		self.hero_copy()!
	}
	mut j := osal.exec(
		name:               cmd.name
		cmd:                cmd_str
		description:        cmd.description
		timeout:            cmd.timeout
		stdout:             cmd.stdout
		stdout_log:         cmd.stdout_log
		raise_error:        cmd.raise_error
		ignore_error:       cmd.ignore_error
		ignore_error_codes: cmd.ignore_error_codes
		scriptpath:         cmd.scriptpath
		scriptkeep:         cmd.scriptkeep
		debug:              cmd.debug
		shell:              cmd.shell
		retry:              cmd.retry
		interactive:        cmd.interactive
		async:              cmd.async
	) or {
		mut epath := pathlib.get_file(path: scriptpath, create: false)!
		c := epath.read()!
		return error('cannot execute:\n${c}\nerror:\n${err}')
	}
	return j
}
