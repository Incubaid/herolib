module herofs

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.core.redisclient

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

@[params]
pub struct DBArgs {
pub mut:
	redis ?&redisclient.Redis
}

pub fn new(args DBArgs) !FsFactory {
	mut mydb := db.new(redis:args.redis)!
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

// is the main function we need to use to get a filesystem, will get it from database and initialize if needed
pub fn new_fs(args FsArg) !Fs {
	mut f := new()!
	mut fs := f.fs.new_get_set(args)!
	return fs
}

pub fn new_fs_test() !Fs {
	mut r:=redisclient.test_get()!
	mut f := new(redis:r)!
	mut fs := f.fs.new_get_set(name: 'test')!
	return fs
}

pub fn delete_fs_test() ! {
	mut r:=redisclient.test_get()!
	r.flush()!
}
