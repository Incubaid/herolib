module main

import incubaid.herolib.core

fn do() ! {
	// base.uninstall_brew()!
	// println("something")
	if core.is_osx()! {
		println('IS OSX')
	}

	// mut job2 := osal.exec(cmd: 'ls /')!
	// println(job2)
}

fn main() {
	do() or { panic(err) }
}
