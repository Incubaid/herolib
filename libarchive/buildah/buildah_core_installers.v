module buildah

import incubaid.herolib.osal.core as osal
// import incubaid.herolib.ui.console
import incubaid.herolib.installers.lang.herolib
import incubaid.herolib.core.pathlib
import os
import json

pub fn (mut self BuildAHContainer) install_zinit() ! {
	// https://github.com/threefoldtech/zinit
	self.hero_copy()!
	self.hero_play_execute('!!installer.zinit')
	//	TODO: implement by making sure hero is in the build context and then use hero cmd to install this
	self.set_entrypoint('/sbin/zinit init --container')!
}

pub fn (mut self BuildAHContainer) install_herodb() ! {
	self.install_zinit()!
	// the hero database gets installed and put in zinit for automatic start
	self.hero_play_execute('!!installer.herodb')
	// TODO: the hero_play needs to be implemented
}

// copies the hero from host into guest
pub fn (mut self BuildAHContainer) install_mycelium() ! {
	self.install_zinit()!
	// the mycelium database gets installed and put in zinit for automatic start
	self.hero_play_execute('!!installer.mycelium')
	// TODO: the hero_play needs to be implemented
}
