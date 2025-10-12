#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.virt.docker

mut engine := docker.new()!

engine.reset_all()!

println(engine)
