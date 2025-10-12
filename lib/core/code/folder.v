module code

import incubaid.herolib.core.pathlib

pub interface IFolder {
	name    string
	files   []IFile
	modules []Module
	write(string, WriteOptions) !
}

pub struct Folder {
pub:
	name    string
	files   []IFile
	folders []IFolder
	modules []Module
}

pub fn (f Folder) write(path string, options WriteOptions) ! {
	mut dir := pathlib.get_dir(
		path:  '${path}/${f.name}'
		empty: options.overwrite
	)!

	if !options.overwrite && dir.exists() {
		return
	}

	for file in f.files {
		file.write(dir.path, options)!
	}
	for folder in f.folders {
		folder.write(dir.path, options)!
	}
	for mod in f.modules {
		mod.write(dir.path, options)!
	}
}
