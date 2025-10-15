module rclone

import incubaid.herolib.data.encoderhero

pub const version = '1.67.0'
const singleton = false
const default = false

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
pub enum RCloneCat {
	b2
	s3
	ftp
}

@[heap]
pub struct RClone {
pub mut:
	name        string = 'default'
	cat         RCloneCat
	s3_account  string
	s3_key      string
	s3_secret   string
	hard_delete bool // hard delete a file when delete on server, not just hide
	endpoint    string
}

// your checking & initialization code if needed
fn obj_init(mycfg_ RClone) !RClone {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	_ := get()!

	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED

	_ := $tmpl('templates/rclone.yaml')
	// mut path := pathlib.get_file(path: cfg.configpath, create: true)!
	// path.write(mycode)!
	// console.print_debug(mycode)
	// implement if steps need to be done for configuration
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj RClone) !string {
	return encoderhero.encode[RClone](obj)!
}

pub fn heroscript_loads(heroscript string) !RClone {
	mut obj := encoderhero.decode[RClone](heroscript)!
	return obj
}
