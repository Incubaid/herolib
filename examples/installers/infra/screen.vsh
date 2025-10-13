#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.infra.screen as screen_installer

mut screen := screen_installer.get()!

screen.install()!
screen.destroy()!
