#!/usr/bin/env -S v -n -w -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.buildah as buildah_installer

mut buildah := buildah_installer.get()!

// To install
buildah.install()!

// To remove
buildah.destroy()!
