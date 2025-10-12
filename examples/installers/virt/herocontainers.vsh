#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.osal
import incubaid.herolib.installers.lang.golang
import incubaid.herolib.installers.virt.podman as podman_installer
import incubaid.herolib.installers.virt.buildah as buildah_installer

mut podman_installer0 := podman_installer.get()!
mut buildah_installer0 := buildah_installer.get()!

// podman_installer0.destroy()! //will remove all

podman_installer0.install()!
buildah_installer0.install()!
