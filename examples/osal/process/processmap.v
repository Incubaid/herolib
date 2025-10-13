module main

import incubaid.herolib.osal

fn do() ? {
	mut pm := process.processmap_get()?
	println(pm)
}

fn main() {
	do() or { panic(err) }
}
