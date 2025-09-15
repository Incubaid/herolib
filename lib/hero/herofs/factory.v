module herofs

import freeflowuniverse.herolib.hero.db

@[heap]
pub struct FsFactory {
pub mut:
	fs                 DBFs
	fs_blob            DBFsBlob
	fs_blob_membership DBFsBlobMembership
	fs_dir             DBFsDir
	fs_file            DBFsFile
	fs_symlink         DBFsSymlink
}

pub fn new() !FsFactory {
	mut mydb := db.new()!
	mut f := FsFactory{
		fs:                 DBFs{
			db: &mydb
		}
		fs_blob:            DBFsBlob{
			db: &mydb
		}
		fs_blob_membership: DBFsBlobMembership{
			db: &mydb
		}
		fs_dir:             DBFsDir{
			db: &mydb
		}
		fs_file:            DBFsFile{
			db: &mydb
		}
		fs_symlink:         DBFsSymlink{
			db: &mydb
		}
	}
	f.fs.factory = &f
	f.fs_blob.factory = &f
	f.fs_blob_membership.factory = &f
	f.fs_dir.factory = &f
	f.fs_file.factory = &f
	f.fs_symlink.factory = &f
	return f
}
