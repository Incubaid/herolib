module herofs

import freeflowuniverse.herolib.data.ourtime

// FsTools provides high-level filesystem operations
pub struct FsTools {
pub mut:
	factory &FsFactory @[skip; str: skip]
	fs_id   u32
}

// Create a new FsTools instance, this is always linked to a specific filesystem
pub fn (factory &FsFactory) fs_tools(fsid u32) FsTools {
	return FsTools{
		factory: factory
		fs_id:   fsid
	}
}
