import incubaid.herolib.dav.webdav
import cli { Command, Flag }
import os

fn main() {
	mut cmd := Command{
		name:        'webdav'
		description: 'Vlang Webdav Server'
	}

	mut app := Command{
		name:        'webdav'
		description: 'Vlang Webdav Server'
		execute:     fn (cmd Command) ! {
			port := cmd.flags.get_int('port')!
			directory := cmd.flags.get_string('directory')!
			user := cmd.flags.get_string('user')!
			password := cmd.flags.get_string('password')!

			mut server := webdav.new_app(
				root_dir:    directory
				server_port: port
				user_db:     {
					user: password
				}
			)!

			server.run()
			return
		}
	}

	app.add_flag(Flag{
		flag:          .int
		name:          'port'
		abbrev:        'p'
		description:   'server port'
		default_value: ['8000']
	})

	app.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'directory'
		abbrev:      'd'
		description: 'server directory'
	})

	app.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'user'
		abbrev:      'u'
		description: 'username'
	})

	app.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'password'
		abbrev:      'pw'
		description: 'user password'
	})

	app.setup()
	app.parse(os.args)
}
