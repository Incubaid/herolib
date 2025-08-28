module tmux

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.texttools
// import freeflowuniverse.herolib.session
import os
import time
import freeflowuniverse.herolib.ui.console

@[heap]
pub struct Tmux {
pub mut:
	sessions  []&Session
	sessionid string // unique link to job
}

// get session (session has windows) .
// returns none if not found
pub fn (mut t Tmux) session_get(name_ string) !&Session {
	name := texttools.name_fix(name_)
	for s in t.sessions {
		if s.name == name {
			return s
		}
	}
	return error('Can not find session with name: \'${name_}\', out of loaded sessions.')
}

pub fn (mut t Tmux) session_exist(name_ string) bool {
	name := texttools.name_fix(name_)
	t.session_get(name) or { return false }
	return true
}

pub fn (mut t Tmux) session_delete(name_ string) ! {
	if !(t.session_exist(name_)) {
		return
	}
	name := texttools.name_fix(name_)
	mut i := 0
	for mut s in t.sessions {
		if s.name == name {
			s.stop()!
			break
		}
		i += 1
	}
	t.sessions.delete(i)
}

@[params]
pub struct SessionCreateArgs {
pub mut:
	name  string @[required]
	reset bool
}

// create session, if reset will re-create
pub fn (mut t Tmux) session_create(args SessionCreateArgs) !&Session {
	name := texttools.name_fix(args.name)
	if !(t.session_exist(name)) {
		$if debug {
			console.print_header(' tmux - create session: ${args}')
		}
		mut s2 := Session{
			tmux: t // reference back
			name: name
		}
		s2.create()!
		t.sessions << &s2
	}
	mut s := t.session_get(name)!
	if args.reset {
		$if debug {
			console.print_header(' tmux - session ${name} will be restarted.')
		}
		s.restart()!
	}
	t.scan()!
	return s
}

@[params]
pub struct TmuxNewArgs {
	sessionid string
}

// return tmux instance
pub fn new(args TmuxNewArgs) !Tmux {
	mut t := Tmux{
		sessionid: args.sessionid
	}
	// t.load()!
	t.scan()!
	return t
}

@[params]
pub struct WindowNewArgs {
pub mut:
	session_name string = 'main'
	name         string
	cmd          string
	env          map[string]string
	reset        bool
}

pub fn (mut t Tmux) window_new(args WindowNewArgs) !&Window {
	// Get or create session
	mut session := if t.session_exist(args.session_name) {
		t.session_get(args.session_name)!
	} else {
		t.session_create(name: args.session_name)!
	}

	// Create window in session
	return session.window_new(
		name:  args.name
		cmd:   args.cmd
		env:   args.env
		reset: args.reset
	)!
}

pub fn (mut t Tmux) stop() ! {
	$if debug {
		console.print_debug('Stopping tmux...')
	}

	t.sessions = []&Session{}
	t.scan()!

	for _, mut session in t.sessions {
		session.stop()!
	}

	cmd := 'tmux kill-server'
	_ := osal.exec(cmd: cmd, stdout: false, name: 'tmux_kill_server', ignore_error: true) or {
		panic('bug')
	}
	os.log('TMUX - All sessions stopped .')
}

pub fn (mut t Tmux) start() ! {
	cmd := 'tmux new-sess -d -s main'
	_ := osal.exec(cmd: cmd, stdout: false, name: 'tmux_start') or {
		return error("Can't execute ${cmd} \n${err}")
	}
	// scan and add default bash window created with session init
	time.sleep(time.Duration(100 * time.millisecond))
	t.scan()!
}

// print list of tmux sessions
pub fn (mut t Tmux) list_print() {
	// os.log('TMUX - Start listing  ....')
	for _, session in t.sessions {
		for _, window in session.windows {
			console.print_debug(window)
		}
	}
}

// get all windows as found in all sessions
pub fn (mut t Tmux) windows_get() []&Window {
	mut res := []&Window{}
	// os.log('TMUX - Start listing  ....')
	for _, session in t.sessions {
		for _, window in session.windows {
			res << window
		}
	}
	return res
}

// checks whether tmux server is running
pub fn (mut t Tmux) is_running() !bool {
	res := os.execute('tmux info')
	if res.exit_code != 0 {
		if is_tmux_server_not_running_error(res.output) {
			// console.print_debug(" TMUX NOT RUNNING")
			return false
		}
		if res.output.contains('no current client') {
			return true
		}
		return error('could not execute tmux info.\n${res.output}')
	}

	return true
}

pub fn (mut t Tmux) str() string {
	mut out := '# Tmux\n\n'
	for s in t.sessions {
		out += '${*s}\n'
	}
	return out
}
