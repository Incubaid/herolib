#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.podman as podman_installer

mut podman := podman_installer.get()!

// To install
podman.install()!

// To remove
podman.destroy()!
