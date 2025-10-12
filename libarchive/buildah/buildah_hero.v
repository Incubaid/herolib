module buildah

import incubaid.herolib.osal.core as osal

// copies the hero from host into guest and then execute the heroscript or commandline
pub fn (mut self BuildAHContainer) hero_cmd_execute(cmd string) ! {
	self.hero_copy()!
	self.exec(cmd: cmd, runtime: .herocmd)!
}

// send a hero play command to the buildah container
pub fn (mut self BuildAHContainer) hero_play_execute(cmd string) ! {
	self.hero_copy()!
	panic('implement')
}

pub fn (mut self BuildAHContainer) hero_execute_script(cmd string) ! {
	self.hero_copy()!
	self.exec(cmd: cmd, runtime: .heroscript)!
}

// copies the hero from host into guest
pub fn (mut self BuildAHContainer) hero_copy() ! {
	// TODO: check we are on linux, check also the platformtype arm or intel, if not right platform then build hero in container

	panic('implement')

	// if !osal.cmd_exists('hero') {
	// 	herolib.hero_compile()!
	// }
	heropath := osal.cmd_path('hero')!
	self.copy(heropath, '/usr/local/bin/hero')!
}

// get a container where we build hero and export hero from the container so we can use it for hero_copy
pub fn (mut self BuildAHContainer) hero_build() ! {
	panic('implement')
}
