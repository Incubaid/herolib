module docker

import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.installers.ulist

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}
	res << startupmanager.ZProcessNewArgs{
		name: 'docker'
		cmd:  'dockerd'
	}

	return res
}

fn running() !bool {
	console.print_header('Checking if Docker is running')
	is_installed := installed() or {
		return error('Cannot execute command docker, check if the docker is installed or call the `install()` method: ${err}')
	}

	if !is_installed {
		return false
	}

	// Checking if the docker server responed
	cmd := 'docker ps'
	osal.execute_stdout(cmd) or { return false }

	console.print_header('Docker is running')
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
	console.print_header('Checking if Docker is installed')
	cmd := 'docker -v'
	osal.execute_stdout(cmd) or { return false }
	console.print_header('Docker is installed')
	return true
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn install() ! {
	console.print_header('Installing Docker')
	if core.platform()! != .ubuntu {
		return error('only support ubuntu for now')
	}

	mut cmd := '
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "\$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
'

	osal.execute_stdout(cmd) or { return error('Cannot install docker due to: ${err}') }

	cmd = 'sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin'
	osal.execute_stdout(cmd) or { return error('Cannot install docker due to: ${err}') }
	console.print_header('Docker installed sucessfully')
}

fn destroy() ! {
	console.print_header('Removing Docker')
	// Uninstall the Docker Engine, CLI, containerd, and Docker Compose packages:
	mut cmd := 'sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras'
	osal.execute_stdout(cmd) or { return error('Cannot uninstall docker due to: ${err}') }

	// Images, containers, volumes, or custom configuration files on your host aren't automatically removed. To delete all images, containers, and volumes:
	cmd = 'sudo rm -rf /var/lib/docker && sudo rm -rf /var/lib/containerd'
	osal.execute_stdout(cmd) or { return error('Cannot uninstall docker due to: ${err}') }

	// Remove source list and keyrings
	cmd = 'sudo rm /etc/apt/sources.list.d/docker.list && sudo rm /etc/apt/keyrings/docker.asc'
	osal.execute_stdout(cmd) or { return error('Cannot uninstall docker due to: ${err}') }
	console.print_header('Docker is removed')
}
