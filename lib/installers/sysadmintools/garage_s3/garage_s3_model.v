module garage_s3

import incubaid.herolib.data.encoderhero
import incubaid.herolib.ui.console
import incubaid.herolib.core.pathlib
import rand

pub const version = '1.0.1'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct GarageS3 {
pub mut:
	name string = 'default'

	replication_mode    string = '3'
	config_path         string = '/var/garage/config.toml'
	metadata_dir        string = '/var/garage/meta'
	data_dir            string = '/var/garage/data'
	sled_cache_capacity u32    = 128 // in MB
	compression_level   u8     = 1

	rpc_secret        string //{GARAGE_RPCSECRET}
	rpc_bind_addr     string = '[::]:3901'
	rpc_bind_outgoing bool
	rpc_public_addr   string = '127.0.0.1:3901'

	bootstrap_peers []string

	api_bind_addr string = '[::]:3900'
	s3_region     string = 'garage'
	root_domain   string = '.s3.garage'

	web_bind_addr   string = '[::]:3902'
	web_root_domain string = '.web.garage'

	admin_api_bind_addr string = '[::]:3903'
	admin_metrics_token string //{GARAGE_METRICSTOKEN}
	admin_token         string //{GARAGE_ADMINTOKEN}
	admin_trace_sink    string = 'http://localhost:4317'

	reset        bool
	config_reset bool
	start        bool = true
	restart      bool = true
}

// your checking & initialization code if needed
fn obj_init(mycfg_ GarageS3) !GarageS3 {
	mut mycfg := mycfg_

	if mycfg.name == '' {
		mycfg.name = 'default'
	}

	if mycfg.config_path == '' {
		mycfg.config_path = '/var/garage/config.toml'
	}

	if mycfg.replication_mode == '' {
		mycfg.replication_mode = '3'
	}

	if mycfg.metadata_dir == '' {
		mycfg.replication_mode = '/var/garage/meta'
	}

	if mycfg.data_dir == '' {
		mycfg.data_dir = '/var/garage/data'
	}

	if mycfg.sled_cache_capacity == 0 {
		mycfg.sled_cache_capacity = 128
	}

	if mycfg.compression_level == 0 {
		mycfg.compression_level = 1
	}

	if mycfg.rpc_bind_addr == '' {
		mycfg.rpc_bind_addr = '[::]:3901'
	}

	if mycfg.rpc_public_addr == '' {
		mycfg.rpc_public_addr = '127.0.0.1:3901'
	}

	if mycfg.api_bind_addr == '' {
		mycfg.api_bind_addr = '[::]:3900'
	}

	if mycfg.s3_region == '' {
		mycfg.s3_region = 'garage'
	}

	if mycfg.root_domain == '' {
		mycfg.root_domain = '.s3.garage'
	}

	if mycfg.web_bind_addr == '' {
		mycfg.web_bind_addr = '[::]:3902'
	}

	if mycfg.web_root_domain == '' {
		mycfg.web_root_domain = '.web.garage'
	}

	if mycfg.admin_api_bind_addr == '' {
		mycfg.admin_api_bind_addr = '[::]:3903'
	}

	if mycfg.admin_trace_sink == '' {
		mycfg.admin_trace_sink = 'http://localhost:4317'
	}

	if mycfg.admin_token == '' {
		mycfg.admin_token = rand.hex(64)
	}

	if mycfg.admin_metrics_token == '' {
		mycfg.admin_metrics_token = rand.hex(64)
	}

	if mycfg.rpc_secret == '' {
		mycfg.rpc_secret = rand.hex(64)
	}
	return mycfg
}

// called before start if done
fn configure() ! {
	server := get()!
	mut mycode := $tmpl('templates/config.ini')
	mut path := pathlib.get_file(path: server.config_path, create: true)!
	path.write(mycode)!
	console.print_debug(mycode)
}

pub fn heroscript_dumps(obj GarageS3) !string {
	return encoderhero.encode[GarageS3](obj)!
}

pub fn heroscript_loads(heroscript string) !GarageS3 {
	mut obj := encoderhero.decode[GarageS3](heroscript)!
	return obj
}
