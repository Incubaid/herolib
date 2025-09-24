module codewalker

import freeflowuniverse.herolib.core.pathlib

pub struct FileMap {
pub mut:
	source         string
	content        map[string]string
	content_change map[string]string
	errors         []FMError
}

pub fn (mut fm FileMap) content() string {
	mut out := []string{}
	for filepath, filecontent in fm.content {
		out << '===FILE:${filepath}==='
		out << filecontent
	}
	for filepath, filecontent in fm.content_change {
		out << '===FILECHANGE:${filepath}==='
		out << filecontent
	}
	out << '===END==='
	return out.join_lines()
}

// write in new location, all will be overwritten, will only work with full files, not changes
pub fn (mut fm FileMap) export(path string) ! {
	for filepath, filecontent in fm.content {
		dest := '${path}/${filepath}'
		mut filepathtowrite := pathlib.get_file(path: dest, create: true)!
		filepathtowrite.write(filecontent)!
	}
}

@[PARAMS]
pub struct WriteParams {
	path        string
	v_test      bool = true
	v_format    bool = true
	python_test bool
}

// update the files as found in the folder and update them or create
pub fn (mut fm FileMap) write(path string) ! {
	for filepath, filecontent in fm.content {
		dest := '${path}/${filepath}'
		// In future: validate language-specific formatting/tests before overwrite
		mut filepathtowrite := pathlib.get_file(path: dest, create: true)!
		filepathtowrite.write(filecontent)!
	}
	// TODO: phase 2, work with morphe to integrate change in the file
}

pub fn (fm FileMap) get(relpath string) !string {
	return fm.content[relpath] or { return error('File not found: ${relpath}') }
}

pub fn (mut fm FileMap) set(relpath string, content string) {
	fm.content[relpath] = content
}

pub fn (mut fm FileMap) delete(relpath string) {
	fm.content.delete(relpath)
}

pub fn (fm FileMap) find(path string) []string {
	mut result := []string{}
	for filepath, _ in fm.content {
		if filepath.starts_with(path) {
			result << filepath
		}
	}
	return result
}
