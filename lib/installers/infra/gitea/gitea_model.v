module gitea

import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import os
import freeflowuniverse.herolib.clients.mailclient
import freeflowuniverse.herolib.clients.postgresql_client
import rand

pub const version = '1.24.5'
const singleton = true
const default = false

@[heap]
pub struct GiteaServer {
pub mut:
	name                   string = 'default'
	path                   string = '${os.home_dir()}/hero/var/gitea'
	passwd                 string
	domain                 string = 'git.test.com'
	jwt_secret             string = rand.hex(12)
	lfs_jwt_secret         string
	internal_token         string
	secret_key             string
	postgresql_client_name string = 'default'
	mail_client_name       string = 'default'
}

pub fn (obj GiteaServer) config_path() string {
	return '${obj.path}/config.ini'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ GiteaServer) !GiteaServer {
	mut mycfg := mycfg_
	if mycfg.name == '' {
		mycfg.name = 'default'
	}

	if mycfg.path == '' {
		mycfg.path = '${os.home_dir()}/hero/var/gitea'
	}

	if mycfg.passwd == '' {
		mycfg.passwd = rand.hex(12)
	}

	if mycfg.postgresql_client_name == '' {
		mycfg.postgresql_client_name = 'default'
	}

	if mycfg.domain == '' {
		mycfg.domain = 'git.test.com'
	}

	if mycfg.jwt_secret == '' {
		mycfg.jwt_secret = rand.hex(12)
	}

	if mycfg.mail_client_name == '' {
		mycfg.mail_client_name = 'default'
	}
	return mycfg
}

// called before start if done
fn configure() ! {
	mut server := get()!

	if !osal.cmd_exists('gitea') {
		return error('gitea binary not found in path. Please install gitea first.')
	}
	// Generate and set any missing secrets
	if server.lfs_jwt_secret == '' {
		server.lfs_jwt_secret = os.execute_opt('gitea generate secret LFS_JWT_SECRET')!.output.trim_space()
		set(server)!
	}
	if server.internal_token == '' {
		server.internal_token = os.execute_opt('gitea generate secret INTERNAL_TOKEN')!.output.trim_space()
		set(server)!
	}
	if server.secret_key == '' {
		server.secret_key = os.execute_opt('gitea generate secret SECRET_KEY')!.output.trim_space()
		set(server)!
	}

	// Initialize required clients with detailed error handling
	mut db_client := postgresql_client.get(name: server.postgresql_client_name) or {
		return error('Failed to initialize PostgreSQL client "${server.postgresql_client_name}": ${err}')
	}
	mut mail_client := mailclient.get(name: server.mail_client_name) or {
		return error('Failed to initialize mail client "${server.mail_client_name}": ${err}')
	}

	// TODO: check database exists
	if !db_client.db_exists('gitea_${server.name}')! {
		console.print_header('Creating database gitea_${server.name} for gitea.')
		db_client.db_create('gitea_${server.name}')!
	}

	db_client.dbname = 'gitea_${server.name}'

	mut mycode := $tmpl('templates/app.ini')
	mut path := pathlib.get_file(path: server.config_path(), create: true)!
	path.write(mycode)!
	console.print_debug(mycode)
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj GiteaServer) !string {
	return encoderhero.encode[GiteaServer](obj)!
}

pub fn heroscript_loads(heroscript string) !GiteaServer {
	mut obj := encoderhero.decode[GiteaServer](heroscript)!
	return obj
}
