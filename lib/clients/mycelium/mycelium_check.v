module mycelium

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import os
import json

pub fn check() bool {
	// if core.is_osx()! {
	// 	mut scr := screen.new(reset: false) or {return False}
	// 	name := 'mycelium'
	// 	if !scr.exists(name) {
	// 		return false
	// 	}
	// }

	// if !(osal.process_exists_byname('mycelium') or {return False}) {
	// 	return false
	// }

	// TODO: might be dangerous if that one goes out
	ping_result := osal.ping(address: '40a:152c:b85b:9646:5b71:d03a:eb27:2462') or { panic(err) }
	if ping_result {
		console.print_debug('could reach 40a:152c:b85b:9646:5b71:d03a:eb27:2462')
		return true
	}
	console.print_stderr('could not reach 40a:152c:b85b:9646:5b71:d03a:eb27:2462')
	return false
}

pub struct MyceliumInspectResult {
pub:
	public_key string @[json: publicKey]
	address    string
}

@[params]
pub struct MyceliumInspectArgs {
pub:
	key_file_path string = '/root/hero/cfg/priv_key.bin'
}

pub fn inspect(args MyceliumInspectArgs) !MyceliumInspectResult {
	command := 'mycelium inspect --key-file ${args.key_file_path} --json'
	result := os.execute(command)

	if result.exit_code != 0 {
		return error('Command failed: ${result.output}')
	}

	inspect_result := json.decode(MyceliumInspectResult, result.output) or {
		return error('Failed to parse JSON: ${err}')
	}

	return inspect_result
}

// if returns empty then probably mycelium is not installed
pub fn ipaddr() string {
	r := inspect() or { MyceliumInspectResult{} }
	return r.address
}
