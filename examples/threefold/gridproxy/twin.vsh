#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.threefold.grid3.gridproxy
import incubaid.herolib.ui.console

fn get_all_twins_example() ! {
	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mytwins := gp_client.get_twins()!

	console.print_debug('${mytwins}')
}

fn get_twin_by_id_example(twin_id u64) ! {
	mut myfilter := gridproxy.twinfilter()!

	myfilter.twin_id = twin_id

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mytwins := gp_client.get_twins(myfilter)!

	console.print_debug('${mytwins}')
}

get_all_twins_example()!
get_twin_by_id_example(u64(800))!
