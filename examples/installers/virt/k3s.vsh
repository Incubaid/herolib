#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.k3s

mut kubectl := k3s.new()!

// To install
kubectl.install()!

// To remove
kubectl.destroy()!
