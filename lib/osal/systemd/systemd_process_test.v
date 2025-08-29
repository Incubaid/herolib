module systemd

// import os
import maps
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console
import os

pub fn testsuite_begin() ! {
	mut systemdfactory := new()!
	mut process := systemdfactory.new(
		cmd:   'redis-server'
		name:  'testservice'
		start: false
	)!

	process.delete()!
}

pub fn testsuite_end() ! {
	mut systemdfactory := new()!
	mut process := systemdfactory.new(
		cmd:   'redis-server'
		name:  'testservice'
		start: false
	)!

	process.delete()!
}

pub fn test_systemd_process_start_stop() ! {
	mut systemdfactory := new()!
	mut process := systemdfactory.new(
		cmd:   'redis-server'
		name:  'testservice'
		start: false
	)!

	process.start()!
	mut status := process.status()!
	assert status == .active

	process.stop()!
	status = process.status()!
	assert status == .inactive
}
