#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.crun_installer

mut crun := crun_installer.get()!

// To install
crun.install()!

// To remove
crun.destroy()!
