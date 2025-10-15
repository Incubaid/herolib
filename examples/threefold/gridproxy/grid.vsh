#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.threefold.grid3.gridproxy
import incubaid.herolib.ui.console

mut gp_client := gridproxy.new(net: .test, cache: true)!

// get twin list
twins := gp_client.get_twins()!
console.print_debug('${twins}')

// get farm list
farms := gp_client.get_farms()!
console.print_debug('${farms}')

// get node list
nodes := gp_client.get_nodes()!
console.print_debug('${nodes}')

// get gateway list
gateways := gp_client.get_gateways()!
console.print_debug('${gateways}')

// get contract list
contracts := gp_client.get_contracts()!
console.print_debug('${contracts}')

// get grid stats
stats := gp_client.get_stats()!
console.print_debug('${stats}')
