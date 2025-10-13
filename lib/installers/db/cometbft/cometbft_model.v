module cometbft

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import os

pub const version = '0.0.0'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct CometBFT {
pub mut:
	name string = 'default'
	// homedir    string
	// configpath string
	// username   string
	// password   string @[secret]
	// title      string
	// host       string
	// port       int
}

// your checking & initialization code if needed
fn obj_init(mycfg_ CometBFT) !CometBFT {
	mut mycfg := mycfg_
	if mycfg.password == '' && mycfg.secret == '' {
		return error('password or secret needs to be filled in for ${mycfg.name}')
	}
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
	// mut mycode := $tmpl('templates/atemplate.yaml')
	// mut path := pathlib.get_file(path: cfg.configpath, create: true)!
	// path.write(mycode)!
	// console.print_debug(mycode)
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj CometBFT) !string {
	return encoderhero.encode[CometBFT](obj)!
}

pub fn heroscript_loads(heroscript string) !CometBFT {
	mut obj := encoderhero.decode[CometBFT](heroscript)!
	return obj
}
