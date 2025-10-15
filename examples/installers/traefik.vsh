#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import incubaid.herolib.installers.web.traefik as traefik_installer

traefik_installer.delete()!
mut installer := traefik_installer.get()!

installer.password = 'planet'
traefik_installer.set(installer)!

installer.start()!
