module b2

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.installers.ulist
import incubaid.herolib.lang.python
import os

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('b2 version')
	return res.exit_code == 0
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn install() ! {
	console.print_header('install b2')
	mut py := python.new()!
	py.update()!
	py.pip('b2')!

	osal.done_set('install_b2', 'OK')!
}

fn destroy() ! {
	console.print_header('uninstall b2')
	// mut py := python.new()! // Should be get function, skiping for now
	// py.update()!
	// py.pip_uninstall('b2')!
}
