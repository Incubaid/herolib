module radixtree

import freeflowuniverse.herolib.ui.console

fn test_debug_deletion() ! {
	console.print_debug('Debug deletion test')
	mut rt := new(path: '/tmp/radixtree_debug_deletion', reset: true)!

	console.print_debug('Inserting car')
	rt.set('car', 'value1'.bytes())!
	rt.print_tree()!

	console.print_debug('Inserting cargo')
	rt.set('cargo', 'value2'.bytes())!
	rt.print_tree()!

	console.print_debug('Testing get cargo before deletion')
	value_before := rt.get('cargo')!
	console.print_debug('cargo value before: ${value_before.bytestr()}')

	console.print_debug('Deleting car')
	rt.delete('car')!
	rt.print_tree()!

	console.print_debug('Testing get cargo after deletion')
	if value_after := rt.get('cargo') {
		console.print_debug('cargo value after: ${value_after.bytestr()}')
	} else {
		console.print_debug('ERROR: cargo not found after deletion')
	}
}
