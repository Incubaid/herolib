#!/usr/bin/env -S v -gc none  -cc tcc -d use_openssl -enable-globals -cg run

import incubaid.herolib.threefold.grid3.deployer

const gigabyte = u64(1024 * 1024 * 1024)

// We can use any of the parameters for the corresponding Grid Proxy query
// https://gridproxy.grid.tf/swagger/index.html#/GridProxy/get_nodes

filter := deployer.FilterNodesArgs{
	size:      5
	randomize: true
	free_mru:  8 * gigabyte
	free_sru:  50 * gigabyte
	farm_name: 'FreeFarm'
	status:    'up'
}

nodes := deployer.filter_nodes(filter)!
println(nodes)
