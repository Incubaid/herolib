#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.threefold.incatokens
import os
import freeflowuniverse.herolib.core.playcmds

current_dir := os.dir(@FILE)
heroscript_path := '${current_dir}/data'

playcmds.run(
	heroscript_path: heroscript_path
)!


println('Simulation complete!')
