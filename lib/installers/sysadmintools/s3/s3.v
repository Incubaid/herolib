module s3

import incubaid.herolib.osal.core as osal
import incubaid.herolib.installers.base
import incubaid.herolib.installers.zinit as zinitinstaller
import incubaid.herolib.installers.rclone
import incubaid.herolib.ui.console

// install s3 will return true if it was already installed
pub fn install_() ! {
	base.install()!
	zinitinstaller.install()!
	rclone.install()!

	if osal.done_exists('install_s3') {
		return
	}

	build()!

	console.print_header('install s3')

	osal.done_set('install_s3', 'OK')!
}
