module heropods

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.core.texttools
import os
import json

@[heap]
pub struct ContainerImage {
pub mut:
	image_name  string @[required] // image is located in /containers/images/<image_name>/rootfs
	docker_url  string // optional docker image URL
	rootfs_path string // path to the extracted rootfs
	size_mb     f64    // size in MB
	created_at  string // creation timestamp
	factory     &ContainerFactory @[skip; str: skip]
}

@[params]
pub struct ContainerImageArgs {
pub mut:
	image_name string @[required] // image is located in /containers/images/<image_name>/rootfs
	docker_url string // docker image URL like "alpine:3.20" or "ubuntu:24.04"
	reset      bool
}

@[params]
pub struct ImageExportArgs {
pub mut:
	dest_path      string @[required] // destination .tgz file path
	compress_level int = 6 // compression level 1-9
}

@[params]
pub struct ImageImportArgs {
pub mut:
	source_path string @[required] // source .tgz file path
	reset       bool // overwrite if exists
}

// Create new image or get existing
pub fn (mut self ContainerFactory) image_new(args ContainerImageArgs) !&ContainerImage {
	mut image_name := texttools.name_fix(args.image_name)
	rootfs_path := '/containers/images/${image_name}/rootfs'

	// Check if image already exists
	if image_name in self.images && !args.reset {
		return self.images[image_name] or { panic('bug') }
	}

	// Ensure podman is installed
	if !osal.cmd_exists('podman') {
		return error('Podman is required for image management. Please install podman first.')
	}

	mut image := &ContainerImage{
		image_name:  image_name
		docker_url:  args.docker_url
		rootfs_path: rootfs_path
		factory:     &self
	}

	// If docker_url is provided, download and extract the image
	if args.docker_url != '' {
		image.download_from_docker(args.docker_url, args.reset)!
	} else {
		// Check if rootfs directory exists
		if !os.is_dir(rootfs_path) {
			return error('Image rootfs not found at ${rootfs_path} and no docker_url provided')
		}
	}

	// Update image metadata
	image.update_metadata()!

	self.images[image_name] = image
	return image
}

// Download image from docker registry using podman
fn (mut self ContainerImage) download_from_docker(docker_url string, reset bool) ! {
	console.print_header('Downloading image: ${docker_url}')

	// Clean image name for local storage
	image_dir := '/containers/images/${self.image_name}'

	// Remove existing if reset is true
	if reset && os.is_dir(image_dir) {
		osal.exec(cmd: 'rm -rf ${image_dir}', stdout: false)!
	}

	// Create image directory
	osal.exec(cmd: 'mkdir -p ${image_dir}', stdout: false)!

	// Pull image using podman
	console.print_debug('Pulling image: ${docker_url}')
	osal.exec(cmd: 'podman pull ${docker_url}', stdout: true)!

	// Create container from image (without running it)
	temp_container := 'temp_${self.image_name}_extract'
	osal.exec(cmd: 'podman create --name ${temp_container} ${docker_url}', stdout: false)!

	// Export container filesystem
	tar_file := '${image_dir}/rootfs.tar'
	osal.exec(cmd: 'podman export ${temp_container} -o ${tar_file}', stdout: true)!

	// Extract to rootfs directory
	osal.exec(cmd: 'mkdir -p ${self.rootfs_path}', stdout: false)!
	osal.exec(cmd: 'tar -xf ${tar_file} -C ${self.rootfs_path}', stdout: true)!

	// Clean up temporary container and tar file
	osal.exec(cmd: 'podman rm ${temp_container}', stdout: false) or {}
	osal.exec(cmd: 'rm -f ${tar_file}', stdout: false) or {}

	// Remove the pulled image from podman to save space (optional)
	osal.exec(cmd: 'podman rmi ${docker_url}', stdout: false) or {}

	console.print_green('Image ${docker_url} extracted to ${self.rootfs_path}')
}

// Update image metadata (size, creation time, etc.)
fn (mut self ContainerImage) update_metadata() ! {
	if !os.is_dir(self.rootfs_path) {
		return error('Rootfs path does not exist: ${self.rootfs_path}')
	}

	// Calculate size
	result := osal.exec(cmd: 'du -sm ${self.rootfs_path}', stdout: false)!
	result_parts := result.output.split_by_space()[0] or { panic('bug') }
	size_str := result_parts.trim_space()
	self.size_mb = size_str.f64()

	// Get creation time
	stat_result := osal.exec(cmd: 'stat -c "%Y" ${self.rootfs_path}', stdout: false)!
	self.created_at = stat_result.output.trim_space() // TODO: should this be ourtime?
}

// List all available images
pub fn (mut self ContainerFactory) images_list() ![]&ContainerImage {
	mut images := []&ContainerImage{}

	images_base_dir := '/containers/images'
	if !os.is_dir(images_base_dir) {
		return images
	}

	// Scan for image directories
	dirs := os.ls(images_base_dir)!
	for dir in dirs {
		full_path := '${images_base_dir}/${dir}'
		if os.is_dir(full_path) {
			rootfs_path := '${full_path}/rootfs'
			if os.is_dir(rootfs_path) {
				// Create image object if not in cache
				if dir !in self.images {
					mut image := &ContainerImage{
						image_name:  dir
						rootfs_path: rootfs_path
						factory:     &self
					}
					image.update_metadata() or {
						console.print_stderr('Failed to update metadata for image ${dir}: ${err}')
						continue
					}
					self.images[dir] = image
				}
				images << self.images[dir] or { panic('bug') }
			}
		}
	}

	return images
}

// Export image to .tgz file
pub fn (mut self ContainerImage) export(args ImageExportArgs) ! {
	if !os.is_dir(self.rootfs_path) {
		return error('Image rootfs not found: ${self.rootfs_path}')
	}

	console.print_header('Exporting image ${self.image_name} to ${args.dest_path}')

	// Ensure destination directory exists
	dest_dir := os.dir(args.dest_path)
	osal.exec(cmd: 'mkdir -p ${dest_dir}', stdout: false)!

	// Create compressed archive
	cmd := 'tar -czf ${args.dest_path} -C ${os.dir(self.rootfs_path)} ${os.base(self.rootfs_path)}'
	osal.exec(cmd: cmd, stdout: true)!

	console.print_green('Image exported successfully to ${args.dest_path}')
}

// Import image from .tgz file
pub fn (mut self ContainerFactory) image_import(args ImageImportArgs) !&ContainerImage {
	if !os.exists(args.source_path) {
		return error('Source file not found: ${args.source_path}')
	}

	// Extract image name from filename
	filename := os.base(args.source_path)
	image_name := filename.replace('.tgz', '').replace('.tar.gz', '')
	image_name_clean := texttools.name_fix(image_name)

	console.print_header('Importing image from ${args.source_path}')

	image_dir := '/containers/images/${image_name_clean}'
	rootfs_path := '${image_dir}/rootfs'

	// Check if image already exists
	if os.is_dir(rootfs_path) && !args.reset {
		return error('Image ${image_name_clean} already exists. Use reset=true to overwrite.')
	}

	// Remove existing if reset
	if args.reset && os.is_dir(image_dir) {
		osal.exec(cmd: 'rm -rf ${image_dir}', stdout: false)!
	}

	// Create directories
	osal.exec(cmd: 'mkdir -p ${image_dir}', stdout: false)!

	// Extract archive
	osal.exec(cmd: 'tar -xzf ${args.source_path} -C ${image_dir}', stdout: true)!

	// Create image object
	mut image := &ContainerImage{
		image_name:  image_name_clean
		rootfs_path: rootfs_path
		factory:     &self
	}

	image.update_metadata()!
	self.images[image_name_clean] = image

	console.print_green('Image imported successfully: ${image_name_clean}')
	return image
}

// Delete image
pub fn (mut self ContainerImage) delete() ! {
	console.print_header('Deleting image: ${self.image_name}')

	image_dir := os.dir(self.rootfs_path)
	if os.is_dir(image_dir) {
		osal.exec(cmd: 'rm -rf ${image_dir}', stdout: true)!
	}

	// Remove from factory cache
	if self.image_name in self.factory.images {
		self.factory.images.delete(self.image_name)
	}

	console.print_green('Image ${self.image_name} deleted successfully')
}

// Get image info as map
pub fn (self ContainerImage) info() map[string]string {
	return {
		'name':        self.image_name
		'docker_url':  self.docker_url
		'rootfs_path': self.rootfs_path
		'size_mb':     self.size_mb.str()
		'created_at':  self.created_at
	}
}

// List available docker images that can be downloaded
pub fn list_available_docker_images() []string {
	return [
		'alpine:3.20',
		'alpine:3.19',
		'alpine:latest',
		'ubuntu:24.04',
		'ubuntu:22.04',
		'ubuntu:20.04',
		'ubuntu:latest',
		'debian:12',
		'debian:11',
		'debian:latest',
		'fedora:39',
		'fedora:38',
		'fedora:latest',
		'archlinux:latest',
		'centos:stream9',
		'rockylinux:9',
		'nginx:alpine',
		'redis:alpine',
		'postgres:15-alpine',
		'node:20-alpine',
		'python:3.12-alpine',
	]
}
