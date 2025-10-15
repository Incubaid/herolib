#!/usr/bin/env -S v -n -w -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.docker as docker_installer

mut docker := docker_installer.get()!

// To install
docker.install()!

// To remove
docker.destroy()!
