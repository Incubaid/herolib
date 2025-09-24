module rclone

import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.data.encoderhero
import os

pub const version = '0.0.0'
const singleton = true
const default = true

pub fn heroscript_default() !string {
	name := os.getenv_opt('RCLONE_NAME') or { 'default' }
	remote_type := os.getenv_opt('RCLONE_TYPE') or { 's3' }
	provider := os.getenv_opt('RCLONE_PROVIDER') or { 'aws' }
	access_key := os.getenv_opt('RCLONE_ACCESS_KEY') or { '' }
	secret_key := os.getenv_opt('RCLONE_SECRET_KEY') or { '' }
	region := os.getenv_opt('RCLONE_REGION') or { 'us-east-1' }
	endpoint := os.getenv_opt('RCLONE_ENDPOINT') or { '' }

	heroscript := "
    !!rclone.configure 
        name: '${name}'
        type: '${remote_type}'
        provider: '${provider}'
        access_key: '${access_key}'
        secret_key: '${secret_key}'
        region: '${region}'
        endpoint: '${endpoint}'
    "

	return heroscript
}

@[heap]
pub struct RCloneClient {
pub mut:
	name       string = 'default'
	type_      string = 's3'  // remote type (s3, sftp, etc)
	provider   string = 'aws' // provider for s3 (aws, minio, etc)
	access_key string // access key for authentication
	secret_key string // secret key for authentication
	region     string = 'us-east-1' // region for s3
	endpoint   string // custom endpoint URL if needed
}

fn cfg_play(p paramsparser.Params) ! {
	mut mycfg := RCloneClient{
		name:       p.get_default('name', 'default')!
		type_:      p.get_default('type', 's3')!
		provider:   p.get_default('provider', 'aws')!
		access_key: p.get('access_key')!
		secret_key: p.get('secret_key')!
		region:     p.get_default('region', 'us-east-1')!
		endpoint:   p.get_default('endpoint', '')!
	}
	set(mycfg)!
}

fn obj_init(obj_ RCloneClient) !RCloneClient {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj RCloneClient) !string {
	return encoderhero.encode[RCloneClient](obj)!
}

pub fn heroscript_loads(heroscript string) !RCloneClient {
	mut obj := encoderhero.decode[RCloneClient](heroscript)!
	return obj
}
