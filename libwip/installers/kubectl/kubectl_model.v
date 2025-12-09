module kubectl

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import os

pub const version = '0.0.0'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct Kubectl {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ Kubectl) !Kubectl {
	mut mycfg := mycfg_
	// if mycfg.password == '' && mycfg.secret == '' {
	//    return error('password or secret needs to be filled in for ${mycfg.name}')
	//}
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !Kubectl {
	mut obj := encoderhero.decode[Kubectl](heroscript)!
	return obj
}
