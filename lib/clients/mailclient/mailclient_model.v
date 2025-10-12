module mailclient

import incubaid.herolib.data.paramsparser
import os

pub const version = '0.0.0'
const singleton = false
const default = true

pub fn heroscript_default(args DefaultConfigArgs) !string {
	mail_from := os.getenv_opt('MAIL_FROM') or { 'info@example.com' }
	mail_password := os.getenv_opt('MAIL_PASSWORD') or { 'secretpassword' }
	mail_port := (os.getenv_opt('MAIL_PORT') or { '465' }).int()
	mail_server := os.getenv_opt('MAIL_SERVER') or { 'smtp-relay.brevo.com' }
	mail_username := os.getenv_opt('MAIL_USERNAME') or { 'mail@incubaid.com' }

	heroscript := "
!!mailclient.configure name:'${args.instance}'
    mail_from: '${mail_from}'
    mail_password: '${mail_password}'
    mail_port: ${mail_port}
    mail_server: '${mail_server}'
    mail_username: '${mail_username}'  
"

	return heroscript
}

@[heap]
pub struct MailClient {
pub mut:
	name          string = 'default'
	mail_from     string
	mail_password string @[secret]
	mail_port     int = 465
	mail_server   string
	mail_username string
	ssl           bool = true
	tls           bool
}

fn cfg_play(p paramsparser.Params) ! {
	mut mycfg := MailClient{
		name:          p.get_default('name', 'default')!
		mail_from:     p.get('mail_from')!
		mail_password: p.get('mail_password')!
		mail_port:     p.get_int_default('mail_port', 465)!
		mail_server:   p.get('mail_server')!
		mail_username: p.get('mail_username')!
	}
	set(mycfg)!
}

fn obj_init(obj_ MailClient) !MailClient {
	mut obj := obj_
	return obj
}
