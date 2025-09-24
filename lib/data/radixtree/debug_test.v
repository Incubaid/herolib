module radixtree

import freeflowuniverse.herolib.ui.console

fn test_simple_debug() ! {
	console.print_debug('=== Simple Debug Test ===')
	mut rt := new(path: '/tmp/radixtree_debug_test', reset: true)!

	console.print_debug('Inserting "foobar"')
	rt.set('foobar', 'value1'.bytes())!
	rt.print_tree()!

	console.print_debug('Getting "foobar"')
	value1 := rt.get('foobar')!
	console.print_debug('Got value: ${value1.bytestr()}')

	console.print_debug('Inserting "foobaz"')
	rt.set('foobaz', 'value2'.bytes())!
	rt.print_tree()!

	console.print_debug('Getting "foobar" again')
	value1_again := rt.get('foobar')!
	console.print_debug('Got value: ${value1_again.bytestr()}')

	console.print_debug('Getting "foobaz"')
	value2 := rt.get('foobaz')!
	console.print_debug('Got value: ${value2.bytestr()}')

	console.print_debug('Listing all keys')
	all_keys := rt.list('')!
	console.print_debug('All keys: ${all_keys}')
}
