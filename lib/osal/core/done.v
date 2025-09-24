module core

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.ui.console

fn donedb() !&redisclient.Redis {
	mut context := base.context()!
	return context.redis()!
}

pub fn done_set(key string, val string) ! {
	mut db := donedb()!
	db.hset('context:done', key, val)!
}

pub fn done_get(key string) ?string {
	mut db := donedb() or { panic(err) }
	return db.hget('context:done', key) or { return none }
}

pub fn done_delete(key string) ! {
	mut db := donedb()!
	db.hdel('context:done', key)!
}

pub fn done_get_str(key string) string {
	val := done_get(key) or { panic(err) }
	return val
}

pub fn done_get_int(key string) int {
	val := done_get(key) or { panic(err) }
	return val.int()
}

pub fn done_exists(key string) bool {
	mut db := donedb() or { panic(err) }
	return db.hexists('context:done', key) or { false }
}

pub fn done_print() ! {
	mut db := donedb()!
	mut output := 'DONE:\n'
	kyes := db.keys('')!
	println('kyes: ${kyes}')
	for key in kyes {
		output += '\t${key} = ${done_get_str(key)}\n'
	}
	console.print_debug('${output}')
}

pub fn done_reset() ! {
	mut db := donedb()!
	db.del('context:done')!
}
