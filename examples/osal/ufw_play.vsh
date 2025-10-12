#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.osal.ufw
import incubaid.herolib.core.playbook

heroscript := "
    !!ufw.configure
        active: true
        ssh: true
        reset: true

    !!ufw.add_rule
        allow: true
        port: 80
        from: 'any'
        tcp: true
        udp: false
        ipv6: false

    !!ufw.add_rule
        allow: false
        port: 443
        from: '192.168.1.0/24'
        tcp: true
        udp: false
        ipv6: false

    !!ufw.add_rule
        allow: true
        port: 53
        from: 'any'
        tcp: true
        udp: true
        ipv6: true
    "

mut plbook := playbook.new(text: heroscript)!
rs := ufw.play(mut plbook)!
println(rs)
