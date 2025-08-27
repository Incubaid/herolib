module podman

import os
import freeflowuniverse.herolib.osal.core as osal { exec }
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.installers.virt.podman as podman_installer
import freeflowuniverse.herolib.installers.lang.herolib
import freeflowuniverse.herolib.ui.console
import json
import rand

@[heap]
pub struct PodmanFactory {
pub mut:
	// sshkeys_allowed []string // all keys here have access over ssh into the machine, when ssh enabled
	images     []Image
	containers []Container
	builders   []Builder
	buildpath  string
	// cache           bool = true
	// push            bool
	// platform        []BuildPlatformType // used to build
	// registries      []BAHRegistry    // one or more supported BAHRegistries
	prefix string
}

// BuildPlatformType represents different build platforms
pub enum BuildPlatformType {
	linux_amd64
	linux_arm64
	darwin_amd64
	darwin_arm64
}

// ContainerRuntimeConfig represents container runtime configuration
pub struct ContainerRuntimeConfig {
pub mut:
	name        string
	image       string
	command     []string
	env         map[string]string
	ports       []string
	volumes     []string
	detach      bool = true
	remove      bool
	interactive bool
	tty         bool
	working_dir string
	entrypoint  string
}

@[params]
pub struct NewArgs {
pub mut:
	install     bool = true
	reset       bool
	herocompile bool
}

pub fn new(args_ NewArgs) !PodmanFactory {
	mut args := args_

	// Support both Linux and macOS
	if !core.is_linux()! && !core.is_osx()! {
		return error('only linux and macOS supported as host for now')
	}

	if args.install {
		mut podman_installer0 := podman_installer.get()!
		podman_installer0.install()!
	}

	// Ensure podman machine is available (macOS/Windows)
	ensure_machine_available() or {
		console.print_debug('Warning: Failed to ensure podman machine availability: ${err}')
		console.print_debug('Continuing anyway - podman operations may fail if machine is not running')
	}

	if args.herocompile {
		herolib.check()! // will check if install, if not will do
		herolib.hero_compile(reset: true)!
	}

	mut factory := PodmanFactory{}
	factory.init()!
	if args.reset {
		factory.reset_all()!
	}

	return factory
}

fn (mut e PodmanFactory) init() ! {
	if e.buildpath == '' {
		e.buildpath = '/tmp/builder'
		exec(cmd: 'mkdir -p ${e.buildpath}', stdout: false)!
	}
	e.load()!
}

// reload the state from system
pub fn (mut e PodmanFactory) load() ! {
	e.builders_load()!
	e.images_load()!
	e.containers_load()!
}

// reset all images & containers, CAREFUL!
pub fn (mut e PodmanFactory) reset_all() ! {
	e.load()!
	for mut container in e.containers.clone() {
		container.delete()!
	}
	for mut image in e.images.clone() {
		image.delete(true)!
	}
	exec(cmd: 'podman rm -a -f', stdout: false)!
	exec(cmd: 'podman rmi -a -f', stdout: false)!
	e.builders_delete_all()!
	osal.done_reset()!
	// Only check systemctl on Linux
	if core.is_linux()! && core.platform()! == core.PlatformType.arch {
		exec(cmd: 'systemctl status podman.socket', stdout: false)!
	}
	e.load()!
}

// Get free port - simple implementation
pub fn (mut e PodmanFactory) get_free_port() ?int {
	// Simple implementation - return a random port in the range
	// In a real implementation, you'd check for port availability
	return 20000 + (rand.int() % 20000)
}

// create_from_buildah_image creates a podman container from a buildah image
pub fn (mut e PodmanFactory) create_from_buildah_image(image_name string, config ContainerRuntimeConfig) !string {
	// Check if image exists in podman
	image_exists := e.image_exists(repo: image_name) or { false }

	if !image_exists {
		// Try to transfer from buildah to podman
		exec(cmd: 'buildah push ${image_name} containers-storage:${image_name}') or {
			return new_image_error('create_from_buildah', image_name, 1, 'Failed to transfer image from buildah',
				err.msg())
		}
		// Reload images after transfer
		e.images_load()!
	}

	// Create container using the image
	args := ContainerCreateArgs{
		name:             config.name
		image_repo:       image_name
		command:          config.command.join(' ')
		env:              config.env
		forwarded_ports:  config.ports
		mounted_volumes:  config.volumes
		detach:           config.detach
		remove_when_done: config.remove
		interactive:      config.interactive
	}

	container := e.container_create(args)!
	return container.id
}

// build_and_run_workflow performs a complete buildah build to podman run workflow
pub fn (mut e PodmanFactory) build_and_run_workflow(build_config ContainerRuntimeConfig, run_config ContainerRuntimeConfig, image_name string) !string {
	// Simple implementation - just create a container from the image
	// In a full implementation, this would coordinate with buildah
	return e.create_from_buildah_image(image_name, run_config)
}

// Simple API functions (from client.v) - these use a default factory instance

// run_container runs a container with the specified image and options.
// Returns the container ID of the created container.
pub fn run_container(image string, options RunOptions) !string {
	mut factory := new(install: false)!

	// Convert RunOptions to ContainerCreateArgs
	args := ContainerCreateArgs{
		name:             options.name
		image_repo:       image
		command:          options.command.join(' ')
		env:              options.env
		forwarded_ports:  options.ports
		mounted_volumes:  options.volumes
		detach:           options.detach
		interactive:      options.interactive
		remove_when_done: options.remove
		// Map other options as needed
	}

	container := factory.container_create(args)!
	return container.id
}

// exec_podman executes a podman command with the given arguments
fn exec_podman(args []string) !string {
	cmd := 'podman ' + args.join(' ')
	result := exec(cmd: cmd, stdout: false)!
	return result.output
}

// parse_json_output parses JSON output into the specified type
fn parse_json_output[T](output string) ![]T {
	if output.trim_space() == '' {
		return []T{}
	}
	return json.decode([]T, output)!
}

// list_containers lists running containers, or all containers if all=true.
pub fn list_containers(all bool) ![]PodmanContainer {
	mut args := ['ps', '--format', 'json']
	if all {
		args << '--all'
	}

	output := exec_podman(args)!
	return parse_json_output[PodmanContainer](output) or {
		return new_container_error('list', 'containers', 1, err.msg(), err.msg())
	}
}

// list_images lists all available images.
pub fn list_images() ![]PodmanImage {
	output := exec_podman(['images', '--format', 'json'])!
	return parse_json_output[PodmanImage](output) or {
		return new_image_error('list', 'images', 1, err.msg(), err.msg())
	}
}

// inspect_container returns detailed information about a container.
pub fn inspect_container(id string) !PodmanContainer {
	output := exec_podman(['inspect', '--format', 'json', id])!

	containers := parse_json_output[PodmanContainer](output) or {
		return new_container_error('inspect', id, 1, err.msg(), err.msg())
	}

	if containers.len == 0 {
		return new_container_error('inspect', id, 1, 'Container not found', 'Container ${id} not found')
	}

	return containers[0]
}

// stop_container stops a running container.
pub fn stop_container(id string) ! {
	exec_podman(['stop', id]) or { return new_container_error('stop', id, 1, err.msg(), err.msg()) }
}

// remove_container removes a container.
// If force=true, the container will be forcefully removed even if running.
pub fn remove_container(id string, force bool) ! {
	mut args := ['rm']
	if force {
		args << '-f'
	}
	args << id

	exec_podman(args) or { return new_container_error('remove', id, 1, err.msg(), err.msg()) }
}

// remove_image removes an image by ID or name.
// If force=true, the image will be forcefully removed even if in use.
pub fn remove_image(id string, force bool) ! {
	mut args := ['rmi']
	if force {
		args << '-f'
	}
	args << id

	exec_podman(args) or { return new_image_error('remove', id, 1, err.msg(), err.msg()) }
}

// =============================================================================
// MACHINE MANAGEMENT (macOS/Windows support)
// =============================================================================

// Machine represents a podman machine (VM)
pub struct Machine {
pub:
	name    string
	vm_type string
	created string
	last_up string
	cpus    string
	memory  string
	disk    string
	running bool
}

// ensure_machine_available ensures a podman machine is available and running
// This is required on macOS and Windows where podman runs in a VM
pub fn ensure_machine_available() ! {
	// Only needed on macOS and Windows
	if os.user_os() !in ['macos', 'windows'] {
		return
	}

	// Check if any machine exists
	machines := list_machines() or { []Machine{} }

	if machines.len == 0 {
		console.print_debug('No podman machine found, initializing...')
		machine_init() or { return error('Failed to initialize podman machine: ${err}') }
	}

	// Check if a machine is running
	if !is_any_machine_running() {
		console.print_debug('Starting podman machine...')
		machine_start() or { return error('Failed to start podman machine: ${err}') }
	}
}

// list_machines returns all available podman machines
pub fn list_machines() ![]Machine {
	return parse_machine_list_text()!
}

// parse_machine_list_text parses text format output as fallback
fn parse_machine_list_text() ![]Machine {
	job := exec(cmd: 'podman machine list', stdout: false) or {
		return error('Failed to list podman machines: ${err}')
	}

	lines := job.output.split_into_lines()
	if lines.len <= 1 {
		return []Machine{} // No machines or only header
	}

	mut machines := []Machine{}
	for i in 1 .. lines.len {
		line := lines[i].trim_space()
		if line == '' {
			continue
		}

		fields := line.split_any(' \t').filter(it.trim_space() != '')
		if fields.len >= 6 {
			machine := Machine{
				name:    fields[0]
				vm_type: fields[1]
				created: fields[2]
				last_up: fields[3]
				cpus:    fields[4]
				memory:  fields[5]
				disk:    if fields.len > 6 { fields[6] } else { '' }
				running: line.contains('Currently running') || line.contains('Running')
			}
			machines << machine
		}
	}

	return machines
}

// is_any_machine_running checks if any podman machine is currently running
pub fn is_any_machine_running() bool {
	machines := list_machines() or { return false }
	return machines.any(it.running)
}

// machine_init initializes a new podman machine with default settings
pub fn machine_init() ! {
	machine_init_named('podman-machine-default')!
}

// machine_init_named initializes a new podman machine with specified name
pub fn machine_init_named(name string) ! {
	console.print_debug('Initializing podman machine: ${name}')
	exec(cmd: 'podman machine init ${name}', stdout: false) or {
		return error('Failed to initialize podman machine: ${err}')
	}
	console.print_debug('✅ Podman machine initialized: ${name}')
}

// machine_start starts the default podman machine
pub fn machine_start() ! {
	machine_start_named('')!
}

// machine_start_named starts a specific podman machine
pub fn machine_start_named(name string) ! {
	mut cmd := 'podman machine start'
	if name != '' {
		cmd += ' ${name}'
	}

	console.print_debug('Starting podman machine...')
	exec(cmd: cmd, stdout: false) or { return error('Failed to start podman machine: ${err}') }
	console.print_debug('✅ Podman machine started')
}

// machine_stop stops the default podman machine
pub fn machine_stop() ! {
	machine_stop_named('')!
}

// machine_stop_named stops a specific podman machine
pub fn machine_stop_named(name string) ! {
	mut cmd := 'podman machine stop'
	if name != '' {
		cmd += ' ${name}'
	}

	exec(cmd: cmd, stdout: false) or { return error('Failed to stop podman machine: ${err}') }
}
