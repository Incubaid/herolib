module postgresql

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.installers.virt.podman as podman_installer
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.installers.ulist
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut cfg := get()!
	mut res := []startupmanager.ZProcessNewArgs{}
	cmd := "
    mkdir -p ${cfg.volume_path}
    podman run --name ${cfg.container_name} -e POSTGRES_USER=${cfg.user} -e POSTGRES_PASSWORD=\"${cfg.password}\" -v ${cfg.volume_path}:/var/lib/postgresql/data -p ${cfg.port}:5432 --health-cmd=\"pg_isready -U ${cfg.user}\" postgres:latest
    "

	res << startupmanager.ZProcessNewArgs{
		name:        'postgresql'
		cmd:         cmd
		startuptype: .zinit
	}

	return res
}

fn running() !bool {
	cfg := get()!
	cmd := 'podman healthcheck run ${cfg.container_name}'
	result := os.execute(cmd)

	if result.exit_code != 0 {
		return false
	}
	return true
}

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	mut cfg := get()!
	mut podman := podman_installer.get()!
	podman.install()!

	cmd := 'podman healthcheck run ${cfg.container_name}'
	result := os.execute(cmd)

	if result.exit_code != 0 {
		return false
	}
	return true
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn install() ! {
	console.print_header('install postgresql')
	mut podman := podman_installer.get()!
	podman.install()!
	osal.execute_silent('podman pull docker.io/library/postgres:latest')!
}

fn destroy() ! {
	// remove the podman postgresql container
	mut cfg := get()!
	cmd := 'podman rm -f ${cfg.container_name}'
	result := os.execute(cmd)

	if result.exit_code != 0 {
		return error("Postgresql container isn't running: ${result.output}")
	}

	// Remove podman
	mut podman := podman_installer.get()!
	podman.destroy()!

	// Remove zinit service, Q: Do we really need to run the postgresql inside a zinit service? it's already running in a container
	mut zinit_factory := zinit.new()!
	if zinit_factory.exists('postgresql') {
		zinit_factory.stop('postgresql') or {
			return error('Could not stop postgresql service due to: ${err}')
		}
		zinit_factory.delete('postgresql') or {
			return error('Could not delete postgresql service due to: ${err}')
		}
	}
	console.print_header('Postgresql container removed')
}
