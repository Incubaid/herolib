#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.youki

mut youki_installer := youki.get()!

youki_installer.install()!
