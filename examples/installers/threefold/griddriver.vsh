#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.threefold.griddriver

mut griddriver_installer := griddriver.get()!
griddriver_installer.install()!
griddriver_installer.destroy()!
