#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.threefold.grid3.gridproxy
import incubaid.herolib.ui.console

fn get_farms_example() ! {
	mut myfilter := gridproxy.farmfilter()!

	myfilter.country = 'Egypt'
	myfilter.total_ips = u64(10)

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	myfarms := gp_client.get_farms(myfilter)!

	console.print_debug('${myfarms}')
}

fn get_farm_by_name_example(farm_name string) ! {
	mut myfilter := gridproxy.farmfilter()!

	myfilter.name = farm_name

	mut gp_client := gridproxy.new(net: .main, cache: true)!
	myfarms := gp_client.get_farms(myfilter)!

	console.print_debug('${myfarms}')
}

get_farms_example()!
get_farm_by_name_example('freefarm')!
