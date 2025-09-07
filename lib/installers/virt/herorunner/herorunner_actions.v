module herorunner

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.installers.ulist
import os

//////////////////// following actions are not specific to instance of the object

fn installed() !bool {
	return false
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

fn upload() ! {
}

fn install() ! {
	console.print_header('install herorunner')
	osal.package_install('crun')!

	// osal.exec(
	// 	cmd:    '

	// 	'
	// 	stdout: true
	// 	name:   'herorunner_install'
	// )!
}

fn destroy() ! {
	// mut systemdfactory := systemd.new()!
	// systemdfactory.destroy("zinit")!

	// osal.process_kill_recursive(name:'zinit')!
	// osal.cmd_delete('zinit')!

	// osal.package_remove('
	//    podman
	//    conmon
	//    buildah
	//    skopeo
	//    runc
	// ')!

	// //will remove all paths where go/bin is found
	// osal.profile_path_add_remove(paths2delete:"go/bin")!

	// osal.rm("
	//    podman
	//    conmon
	//    buildah
	//    skopeo
	//    runc
	//    /var/lib/containers
	//    /var/lib/podman
	//    /var/lib/buildah
	//    /tmp/podman
	//    /tmp/conmon
	// ")!
}
