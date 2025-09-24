module deployer

// import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.data.encoderhero
import os

pub const version = '1.0.0'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

pub enum Network {
	dev
	main
	test
	qa
}

@[heap]
pub struct TFGridDeployer {
pub mut:
	name     string = 'default'
	ssh_key  string
	mnemonic string
	network  Network
}

// your checking & initialization code if needed
fn obj_init(mycfg_ TFGridDeployer) !TFGridDeployer {
	mut mycfg := mycfg_
	ssh_key := os.getenv_opt('SSH_KEY') or { '' }
	if ssh_key.len > 0 {
		mycfg.ssh_key = ssh_key
	}
	mnemonic := os.getenv_opt('TFGRID_MNEMONIC') or { '' }
	if mnemonic.len > 0 {
		mycfg.mnemonic = mnemonic
	}
	network := os.getenv_opt('TFGRID_NETWORK') or { 'main' } //
	if network.len > 0 {
		match network {
			'main' {
				mycfg.network = .main
			}
			'dev' {
				mycfg.network = .dev
			}
			'test' {
				mycfg.network = .test
			}
			'qa' {
				mycfg.network = .qa
			}
			else {
				return error("can't find network with type; ${network}")
			}
		}
	}
	if mycfg.ssh_key.len == 0 {
		return error('ssh_key cannot be empty')
	}
	if mycfg.mnemonic.len == 0 {
		return error('mnemonic cannot be empty')
	}
	// println(mycfg)
	return mycfg
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj TFGridDeployer) !string {
	return encoderhero.encode[TFGridDeployer](obj)!
}

pub fn heroscript_loads(heroscript string) !TFGridDeployer {
	mut obj := encoderhero.decode[TFGridDeployer](heroscript)!
	return obj
}
