module rmb

import incubaid.herolib.ui.console

fn test_main() ? {
	mut cl := new(nettype: .dev)!

	mut r := cl.get_zos_statistics(1)!

	console.print_debug(r)

	panic('ddd')
}
