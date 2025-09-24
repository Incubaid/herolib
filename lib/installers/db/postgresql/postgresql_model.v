module postgresql

import freeflowuniverse.herolib.data.encoderhero

pub const version = '0.0.0'
const singleton = true
const default = true

@[heap]
pub struct Postgresql {
pub mut:
	name           string = 'default'
	user           string = 'postgres'
	password       string = 'postgres'
	host           string = 'localhost'
	volume_path    string = '/var/lib/postgresql/data'
	container_name string = 'postgresql'
	port           int    = 5432
	container_id   string
}

// your checking & initialization code if needed
fn obj_init(mycfg_ Postgresql) !Postgresql {
	mut mycfg := mycfg_
	if mycfg.name == '' {
		mycfg.name = 'default'
	}

	if mycfg.user == '' {
		mycfg.user = 'postgres'
	}

	if mycfg.password == '' {
		mycfg.password = 'postgres'
	}

	if mycfg.host == '' {
		mycfg.host = 'localhost'
	}

	if mycfg.volume_path == '' {
		mycfg.volume_path = '/var/lib/postgresql/data'
	}

	if mycfg.container_name == '' {
		mycfg.container_name = 'herocontainer_postgresql'
	}

	if mycfg.port == 0 {
		mycfg.port = 5432
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

pub fn heroscript_dumps(obj Postgresql) !string {
	return encoderhero.encode[Postgresql](obj)!
}

pub fn heroscript_loads(heroscript string) !Postgresql {
	mut obj := encoderhero.decode[Postgresql](heroscript)!
	return obj
}
