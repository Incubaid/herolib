#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.pacman as pacman_installer

mut pacman := pacman_installer.get()!

// To install
pacman.install()!

// To remove
pacman.destroy()!
