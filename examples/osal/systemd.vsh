#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.osal.systemd

mut systemdfactory := systemd.new()!
// mut systemdprocess := systemdfactory.new(
// 	cmd: '/usr/local/bin/zinit init'
// 	name: 'zinit'
// 	description: 'a super easy to use startup manager.'
// )!
l := systemd.process_list()!
println(l)
systemdfactory.destroy('zinit')!
