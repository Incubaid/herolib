#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.threefold.grid3.gridproxy
import incubaid.herolib.threefold.grid3.gridproxy.model { NodeStatus }
import incubaid.herolib.ui.console

fn get_online_grid_stats_example() ! {
	mut myfilter := gridproxy.statfilter()!

	myfilter.status = NodeStatus.online

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mystats := gp_client.get_stats(myfilter)!

	console.print_debug('${mystats}')
}

fn get_all_grid_stats_example() ! {
	mut myfilter := gridproxy.statfilter()!

	myfilter.status = NodeStatus.all

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mystats := gp_client.get_stats(myfilter)!

	console.print_debug('${mystats}')
}

get_online_grid_stats_example()!
get_all_grid_stats_example()!
