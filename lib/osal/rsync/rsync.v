module rsync

import os
import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import incubaid.herolib.osal.core as osal

@[params]
pub struct RsyncArgs {
pub mut:
	source         string
	dest           string
	ipaddr_src     string // e.g. root@192.168.5.5:33 (can be without root@ or :port)
	ipaddr_dst     string
	delete         bool     // do we want to delete the destination
	ignore         []string // arguments to ignore e.g. ['*.pyc','*.bak']
	ignore_default bool = true // if set will ignore a common set
	stdout         bool
	fast_rsync     bool
	sshkey         string
	// rsync daemon mode options (alternative to SSH)
	daemon_mode    bool   // if true, use rsync daemon protocol instead of SSH
	daemon_port    int    // port for rsync daemon (e.g., 30873)
	daemon_user    string // username for rsync daemon auth (e.g., 'atlas')
	daemon_host    string // host/IP for rsync daemon (e.g., '51.195.61.5')
	daemon_module  string // rsync module path (e.g., 'sites/info')
	password       string // password for rsync daemon auth
}

// flexible tool to sync files from to, does even support ssh .
// args: .
// ```
// 	source string
// 	dest string
// 	delete bool //do we want to delete the destination
//  ipaddr_src string //e.g. root@192.168.5.5:33 (can be without root@ or :port)
//  ipaddr_dst string //can only use src or dst, not both
// 	ignore []string //arguments to ignore
//  ignore_default bool = true //if set will ignore a common set
//  stdout bool = true
//  daemon_mode bool // use rsync daemon protocol instead of SSH
//  daemon_port int // port for rsync daemon
//  daemon_user string // username for rsync daemon auth
//  daemon_host string // host/IP for rsync daemon
//  daemon_module string // rsync module path
//  password string // password for rsync daemon auth
// ```
// .
// see https://github.com/incubaid/herolib/blob/development/examples/pathlib.rsync/rsync_example.v
pub fn rsync(args_ RsyncArgs) ! {
	mut args := args_

	// Use daemon mode if configured
	if args.daemon_mode {
		rsync_daemon(args)!
		return
	}

	if args.ipaddr_src.len == 0 {
		pathlib.get(args.source)
	}
	args2 := pathlib.RsyncArgs{
		source:         args.source
		dest:           args.dest
		ipaddr_src:     args.ipaddr_src
		ipaddr_dst:     args.ipaddr_dst
		delete:         args.delete
		ignore:         args.ignore
		ignore_default: args.ignore_default
		fast_rsync:     args.fast_rsync
		sshkey:         args.sshkey
	}

	// TODO: is only for ssh right now, we prob need support for a real ssh server as well
	cmdoptions := pathlib.rsync_cmd_options(args2)!
	cmd := 'rsync ${cmdoptions}'
	$if debug {
		console.print_debug('rsync command (osal):\n${cmd}')
	}
	// console.print_debug(cmd)
	osal.exec(cmd: cmd, stdout: args_.stdout)!
}

// rsync_daemon performs rsync using the rsync daemon protocol with password authentication.
// This is used for syncing to remote rsync daemons (not SSH-based).
// The password is written to a temporary file which is cleaned up after the operation.
pub fn rsync_daemon(args RsyncArgs) ! {
	if args.daemon_host.len == 0 {
		return error('daemon_host is required for rsync daemon mode')
	}
	if args.daemon_module.len == 0 {
		return error('daemon_module is required for rsync daemon mode')
	}
	if args.password.len == 0 {
		return error('password is required for rsync daemon mode')
	}

	// Create temporary password file
	pass_file := '/tmp/rsync-pass-${os.getpid()}'
	os.write_file(pass_file, args.password)!
	os.chmod(pass_file, 0o600)!
	defer {
		os.rm(pass_file) or {}
	}

	// Build rsync command for daemon mode
	mut cmd_parts := []string{}
	cmd_parts << '-avz'

	if args.delete {
		cmd_parts << '--delete'
	}

	if args.daemon_port > 0 {
		cmd_parts << '--port=${args.daemon_port}'
	}

	cmd_parts << '--password-file=${pass_file}'

	// Add ignore patterns
	mut ignore := args.ignore.clone()
	if args.ignore_default {
		defaultset := ['*.pyc', '*.bak', '*dSYM']
		for item in defaultset {
			if item !in ignore {
				ignore << item
			}
		}
	}
	for excl in ignore {
		cmd_parts << "--exclude='${excl}'"
	}

	// Source path (ensure trailing slash for directory sync)
	mut source := args.source.trim_right('/ ')
	mut src_path := pathlib.get(source)
	if src_path.is_dir() {
		source = source + '/'
	}
	cmd_parts << source

	// Destination: user@host::module/path
	mut dest := ''
	if args.daemon_user.len > 0 {
		dest = '${args.daemon_user}@${args.daemon_host}::${args.daemon_module}/'
	} else {
		dest = '${args.daemon_host}::${args.daemon_module}/'
	}
	cmd_parts << dest

	cmd := 'rsync ' + cmd_parts.join(' ')
	$if debug {
		console.print_debug('rsync daemon command:\n${cmd}')
	}

	osal.exec(cmd: cmd, stdout: args.stdout)!
}
