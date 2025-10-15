module code

import incubaid.herolib.core.pathlib

pub interface IBasicFolder {
	name    string
	files   []IFile
	modules []Module
	write(string, WriteOptions) !
}

pub struct BasicFolder {
pub:
	name    string
	files   []IFile
	folders []IBasicFolder
	modules []Module
}

pub fn (f BasicFolder) write(path string, options WriteOptions) ! {
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
