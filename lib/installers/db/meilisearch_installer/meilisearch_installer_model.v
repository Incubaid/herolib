module meilisearch_installer

import incubaid.herolib.data.encoderhero

pub const version = '1.11.3'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct MeilisearchInstaller {
pub mut:
	name       string = 'default'
	path       string = '/tmp/meilisearch'
	masterkey  string @[secret]
	host       string = 'localhost'
	port       int    = 7700
	production bool
}

// your checking & initialization code if needed
fn obj_init(mycfg_ MeilisearchInstaller) !MeilisearchInstaller {
	mut mycfg := mycfg_
	if mycfg.masterkey == '' {
		mycfg.masterkey = generate_master_key(16)!
	}

	if mycfg.path == '' {
		mycfg.path = '/tmp/meilisearch'
	}

	if mycfg.host == '' {
		mycfg.host = 'localhost'
	}

	if mycfg.port == 0 {
		mycfg.port = 7700
	}

	if mycfg.name == '' {
		mycfg.name = 'default'
	}
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj MeilisearchInstaller) !string {
	return encoderhero.encode[MeilisearchInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !MeilisearchInstaller {
	mut obj := encoderhero.decode[MeilisearchInstaller](heroscript)!
	return obj
}
