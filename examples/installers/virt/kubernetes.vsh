#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.kubernetes_installer

mut kubectl := kubernetes_installer.get(name: 'k_installer', create: true)!

// To install
kubectl.install()!

// To remove
kubectl.destroy()!
