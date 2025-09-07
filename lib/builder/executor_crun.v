module builder

import os
import rand
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.osal.rsync
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.data.ipaddress
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools

@[heap]
pub struct ExecutorCrun {
pub mut:
	container_id string //to map to virt/herorun/container
	retry       int  = 1 // nr of times something will be retried before failing, need to check also what error is, only things which should be retried need to be done
	debug       bool = true
}

fn (mut executor ExecutorCrun) init() ! {
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
		console.print_debug('execute ${executor.ipaddr.addr}: ${args.cmd}')
	}
	//TODO: implement
	res := osal.exec(cmd: args.cmd, stdout: args.stdout, debug: executor.debug)!
	return res.output
}

pub fn (mut executor ExecutorCrun) exec_interactive(args_ ExecArgs) ! {
	mut args := args_
	mut port := ''
	if args.cmd.contains('\n') {
		args.cmd = texttools.dedent(args.cmd)
		// need to upload the file first
		executor.file_write('/tmp/toexec.sh', args.cmd)!
		args.cmd = 'bash /tmp/toexec.sh'
	}
	//TODO: implement

	console.print_debug(args.cmd)
	osal.execute_interactive(args.cmd)!
}

pub fn (mut executor ExecutorCrun) file_write(path string, text string) ! {
	if executor.debug {
		console.print_debug('${executor.ipaddr.addr} file write: ${path}')
	}
	//TODO implement use pathlib and write functionality
}

pub fn (mut executor ExecutorCrun) file_read(path string) !string {
	if executor.debug {
		console.print_debug('${executor.ipaddr.addr} file read: ${path}')
	}
	//TODO implement use pathlib and read functionality
}

pub fn (mut executor ExecutorCrun) file_exists(path string) bool {
	if executor.debug {
		console.print_debug('${executor.ipaddr.addr} file exists: ${path}')
	}
	output := executor.exec(cmd: 'test -f ${path} && echo found || echo not found', stdout: false) or {
		return false
	}
	if output == 'found' {
		return true
	}
	//TODO: can prob be done better, because we can go in the path of the container and check there
	return false
}

// carefull removes everything
pub fn (mut executor ExecutorCrun) delete(path string) ! {
	if executor.debug {
		console.print_debug('${executor.ipaddr.addr} file delete: ${path}')
	}
	executor.exec(cmd: 'rm -rf ${path}', stdout: false) or { panic(err) }
	//TODO: can prob be done better, because we can go in the path of the container and delete there
}

// upload from local FS to executor FS
pub fn (mut executor ExecutorCrun) download(args SyncArgs) ! {
	//TODO implement
	rsync.rsync(rsargs)!
}

// download from executor FS to local FS
pub fn (mut executor ExecutorCrun) upload(args SyncArgs) ! {

	//TODO implement
	mut rsargs := rsync.RsyncArgs{
		source:         args.source
		dest:           args.dest
		delete:         args.delete
		ipaddr_dst:     addr
		ignore:         args.ignore
		ignore_default: args.ignore_default
		stdout:         args.stdout
		fast_rsync:     args.fast_rsync
	}
	rsync.rsync(rsargs)!
}

// get environment variables from the executor
pub fn (mut executor ExecutorCrun) environ_get() !map[string]string {
	env := executor.exec(cmd: 'env', stdout: false) or { return error('can not get environment') }
	// if executor.debug {
	// 	console.print_header(' ${executor.ipaddr.addr} env get')
	// }

	mut res := map[string]string{}
	if env.contains('\n') {
		for line in env.split('\n') {
			if line.contains('=') {
				splitted := line.split('=')
				key := splitted[0].trim(' ')
				val := splitted[1].trim(' ')
				res[key] = val
			}
		}
	}
	return res
}

/*
Executor info or meta data
accessing type Executor won't allow to access the
fields of the struct, so this is workaround
*/
pub fn (mut executor ExecutorCrun) info() map[string]string {
	//TODO implement more info
	return {
		'category':  'crun'
	}
}

// ssh shell on the node default ssh port, or any custom port that may be
// forwarding ssh traffic to certain container

pub fn (mut executor ExecutorCrun) shell(cmd string) ! {
	//TODO: implement 
	if cmd.len > 0 {
		panic('TODO IMPLEMENT SHELL EXEC OVER SSH')
	}
	os.execvp('ssh', ['-o StrictHostKeyChecking=no', '${executor.user}@${executor.ipaddr.addr}',
		'-p ${executor.ipaddr.port}'])!
}

pub fn (mut executor ExecutorCrun) list(path string) ![]string {
	if !executor.dir_exists(path) {
		panic('Dir Not found')
	}
	mut res := []string{}
	//TODO: implement
	output := executor.exec(cmd: 'ls ${path}', stdout: false)!
	for line in output.split('\n') {
		res << line
	}
	return res
}

pub fn (mut executor ExecutorCrun) dir_exists(path string) bool {
	output := executor.exec(cmd: 'test -d ${path} && echo found || echo not found', stdout: false) or {
		return false
	}
	//TODO: implement
	if output.trim_space() == 'found' {
		return true
	}
	return false
}
