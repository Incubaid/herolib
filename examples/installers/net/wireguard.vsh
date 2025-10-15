#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.net.wireguard_installer as wireguard

mut wireguard_installer := wireguard.get()!
wireguard_installer.install()!
wireguard_installer.destroy()!
