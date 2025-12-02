module core

import incubaid.herolib.core.pathlib
import os

pub enum FileType {
	file
	image
}

pub struct File {
pub mut:
	name       string   // name with extension
	path       string   // relative path of file in the collection
	ftype      FileType // file or image
	collection &Collection @[skip; str: skip] // Reference to parent collection
}

// Read content without processing includes
pub fn (mut f File) path() !pathlib.Path {
	mut mypath := '${f.collection.path()!.path}/${f.path}'
	return pathlib.get_file(path: mypath, create: false)!
}

pub fn (f File) is_image() bool {
	return f.ftype == .image
}

pub fn (f File) ext() string {
	return os.file_ext(f.name)
}
