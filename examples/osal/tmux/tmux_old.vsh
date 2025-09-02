#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.osal.tmux

mut t := tmux.new()!
if !t.is_running()! {
	t.start()!
}
if t.session_exist('main') {
	t.session_delete('main')!
}
// Create session first, then create window
mut session := t.session_create(name: 'main')!
session.window_new(name: 'test', cmd: 'mc', reset: true)!

// Or use the convenience method
// t.window_new(session_name: 'main', name: 'test', cmd: 'mc', reset: true)!

println(t)
