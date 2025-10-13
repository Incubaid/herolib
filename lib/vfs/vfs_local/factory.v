module vfs_local

import os
import incubaid.herolib.vfs

// LocalVFS implements vfs.VFSImplementation for local filesystem
pub struct LocalVFS {
mut:
	root_path string
}

// Create a new LocalVFS instance
pub fn new_local_vfs(root_path string) !vfs.VFSImplementation {
	mut myvfs := LocalVFS{
		root_path: root_path
	}
	myvfs.init()!
	return myvfs
}

// Initialize the local vfscore with a root path
fn (mut myvfs LocalVFS) init() ! {
	if !os.exists(myvfs.root_path) {
		os.mkdir_all(myvfs.root_path) or {
			return error('Failed to create root directory ${myvfs.root_path}: ${err}')
		}
	}
}
