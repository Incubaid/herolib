module rcloneclient

import os

// // RCloneClient represents a configured rclone instance
// pub struct RCloneClient {
// pub mut:
// 	name string // name of the remote
// }

// mount mounts a remote at the specified path
pub fn (mut r RCloneClient) mount(remote_path string, local_path string) ! {
	if !os.exists(local_path) {
		os.mkdir_all(local_path) or { return error('Failed to create mount directory: ${err}') }
	}

	cmd := 'rclone mount ${r.name}:${remote_path} ${local_path} --daemon'
	res := os.execute(cmd)
	if res.exit_code != 0 {
		return error('Failed to mount remote: ${res.output}')
	}
}

// unmount unmounts a mounted remote
pub fn (mut r RCloneClient) unmount(local_path string) ! {
	if os.user_os() == 'macos' {
		os.execute_opt('umount ${local_path}') or { return error('Failed to unmount: ${err}') }
	} else {
		os.execute_opt('fusermount -u ${local_path}') or {
			return error('Failed to unmount: ${err}')
		}
	}
}

// upload uploads a file or directory to the remote
pub fn (mut r RCloneClient) upload(local_path string, remote_path string) ! {
	if !os.exists(local_path) {
		return error('Local path does not exist: ${local_path}')
	}

	cmd := 'rclone copy ${local_path} ${r.name}:${remote_path}'
	res := os.execute(cmd)
	if res.exit_code != 0 {
		return error('Failed to upload: ${res.output}')
	}
}

// download downloads a file or directory from the remote
pub fn (mut r RCloneClient) download(remote_path string, local_path string) ! {
	if !os.exists(local_path) {
		os.mkdir_all(local_path) or { return error('Failed to create local directory: ${err}') }
	}

	cmd := 'rclone copy ${r.name}:${remote_path} ${local_path}'
	res := os.execute(cmd)
	if res.exit_code != 0 {
		return error('Failed to download: ${res.output}')
	}
}

// list lists contents of a remote path
pub fn (mut r RCloneClient) list(remote_path string) !string {
	cmd := 'rclone ls ${r.name}:${remote_path}'
	res := os.execute(cmd)
	if res.exit_code != 0 {
		return error('Failed to list remote contents: ${res.output}')
	}
	return res.output
}

// check_installed checks if rclone is installed
pub fn check_installed() bool {
	res := os.execute('which rclone')
	return res.exit_code == 0
}
