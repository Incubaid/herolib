#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.installers.infra.zinit_installer

mut installer := zinit_installer.get()!
installer.install()!
installer.start()!
// installer.destroy()!
