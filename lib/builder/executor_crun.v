module builder

import os
import rand
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools

@[heap]
pub struct ExecutorCrun {
pub mut:
	container_id string // container ID for crun
	retry        int  = 1
	debug        bool = true
}

pub fn (mut executor ExecutorCrun) init() ! {
	// Verify container exists and is running
	result := osal.exec(cmd: 'crun state ${executor.container_id}', stdout: false) or {
		return error('Container ${executor.container_id} not found or not accessible')
	}

	// Parse state to ensure container is running
	if !result.output.contains('"status": "running"') {
		return error('Container ${executor.container_id} is not running')
	}
}

pub fn (mut executor ExecutorCrun) debug_on() {
	executor.debug = true
}

pub fn (mut executor ExecutorCrun) debug_off() {
	executor.debug = false
}

pub fn (mut executor ExecutorCrun) exec(args_ ExecArgs) !string {
	mut args := args_
	if executor.debug {
		console.print_debug('execute in container ${executor.container_id}: ${args.cmd}')
	}

	mut cmd := 'crun exec ${executor.container_id} ${args.cmd}'
	if args.cmd.contains('\n') {
		// For multiline commands, write to temp file first
		temp_script := '/tmp/crun_script_${rand.uuid_v4()}.sh'
		script_content := texttools.dedent(args.cmd)
		os.write_file(temp_script, script_content)!

		// Copy script into container and execute
		executor.file_write('/tmp/exec_script.sh', script_content)!
		cmd = 'crun exec ${executor.container_id} bash /tmp/exec_script.sh'
	}

	res := osal.exec(cmd: cmd, stdout: args.stdout, debug: executor.debug)!
	return res.output
}

pub fn (mut executor ExecutorCrun) exec_interactive(args_ ExecArgs) ! {
	mut args := args_

	if args.cmd.contains('\n') {
		args.cmd = texttools.dedent(args.cmd)
		executor.file_write('/tmp/interactive_script.sh', args.cmd)!
		args.cmd = 'bash /tmp/interactive_script.sh'
	}

	cmd := 'crun exec -t ${executor.container_id} ${args.cmd}'
	console.print_debug(cmd)
	osal.execute_interactive(cmd)!
}

pub fn (mut executor ExecutorCrun) file_write(path string, text string) ! {
	if executor.debug {
		console.print_debug('Container ${executor.container_id} file write: ${path}')
	}

	// Write to temp file first, then copy into container
	temp_file := '/tmp/crun_file_${rand.uuid_v4()}'
	os.write_file(temp_file, text)!
	defer { os.rm(temp_file) or {} }

	// Use crun exec to copy file content
	cmd := 'cat ${temp_file} | crun exec -i ${executor.container_id} tee ${path} > /dev/null'
	osal.exec(cmd: cmd, stdout: false)!
}

pub fn (mut executor ExecutorCrun) file_read(path string) !string {
	if executor.debug {
		console.print_debug('Container ${executor.container_id} file read: ${path}')
	}

	return executor.exec(cmd: 'cat ${path}', stdout: false)
}

pub fn (mut executor ExecutorCrun) file_exists(path string) bool {
	if executor.debug {
		console.print_debug('Container ${executor.container_id} file exists: ${path}')
	}

	output := executor.exec(cmd: 'test -f ${path} && echo found || echo not found', stdout: false) or {
		return false
	}
	return output.trim_space() == 'found'
}

pub fn (mut executor ExecutorCrun) delete(path string) ! {
	if executor.debug {
		console.print_debug('Container ${executor.container_id} delete: ${path}')
	}
	executor.exec(cmd: 'rm -rf ${path}', stdout: false)!
}

pub fn (mut executor ExecutorCrun) upload(args SyncArgs) ! {
	// For container uploads, we need to copy files from host to container
	// Use crun exec with tar for efficient transfer

	mut src_path := pathlib.get(args.source)
	if !src_path.exists() {
		return error('Source path ${args.source} does not exist')
	}

	if src_path.is_dir() {
		// For directories, use tar to transfer
		temp_tar := '/tmp/crun_upload_${rand.uuid_v4()}.tar'
		osal.exec(
			cmd:    'tar -cf ${temp_tar} -C ${src_path.path_dir()} ${src_path.name()}'
			stdout: false
		)!
		defer { os.rm(temp_tar) or {} }

		// Extract in container
		cmd := 'cat ${temp_tar} | crun exec -i ${executor.container_id} tar -xf - -C ${args.dest}'
		osal.exec(cmd: cmd, stdout: args.stdout)!
	} else {
		// For single files
		executor.file_write(args.dest, src_path.read()!)!
	}
}

pub fn (mut executor ExecutorCrun) download(args SyncArgs) ! {
	// Download from container to host
	if executor.dir_exists(args.source) {
		// For directories
		temp_tar := '/tmp/crun_download_${rand.uuid_v4()}.tar'
		cmd := 'crun exec ${executor.container_id} tar -cf - -C ${args.source} . > ${temp_tar}'
		osal.exec(cmd: cmd, stdout: false)!
		defer { os.rm(temp_tar) or {} }

		// Extract on host
		osal.exec(
			cmd:    'mkdir -p ${args.dest} && tar -xf ${temp_tar} -C ${args.dest}'
			stdout: args.stdout
		)!
	} else {
		// For single files
		content := executor.file_read(args.source)!
		os.write_file(args.dest, content)!
	}
}

pub fn (mut executor ExecutorCrun) environ_get() !map[string]string {
	env := executor.exec(cmd: 'env', stdout: false) or {
		return error('Cannot get environment from container ${executor.container_id}')
	}

	mut res := map[string]string{}
	for line in env.split('\n') {
		if line.contains('=') {
			mut key, mut val := line.split_once('=') or { continue }
			key = key.trim(' ')
			val = val.trim(' ')
			res[key] = val
		}
	}
	return res
}

pub fn (mut executor ExecutorCrun) info() map[string]string {
	return {
		'category':     'crun'
		'container_id': executor.container_id
		'runtime':      'crun'
	}
}

pub fn (mut executor ExecutorCrun) shell(cmd string) ! {
	if cmd.len > 0 {
		osal.execute_interactive('crun exec -t ${executor.container_id} ${cmd}')!
	} else {
		osal.execute_interactive('crun exec -t ${executor.container_id} /bin/sh')!
	}
}

pub fn (mut executor ExecutorCrun) list(path string) ![]string {
	if !executor.dir_exists(path) {
		return error('Directory ${path} does not exist in container')
	}

	output := executor.exec(cmd: 'ls ${path}', stdout: false)!
	mut res := []string{}
	for line in output.split('\n') {
		line_trimmed := line.trim_space()
		if line_trimmed != '' {
			res << line_trimmed
		}
	}
	return res
}

pub fn (mut executor ExecutorCrun) dir_exists(path string) bool {
	output := executor.exec(cmd: 'test -d ${path} && echo found || echo not found', stdout: false) or {
		return false
	}
	return output.trim_space() == 'found'
}
