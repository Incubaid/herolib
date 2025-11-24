module codewalker

import incubaid.herolib.core.pathlib

// FileMap represents parsed file structure with content and changes
pub struct FileMap {
pub mut:
	source         string            // Source path or origin
	content        map[string]string // Full file content by path
	content_change map[string]string // Partial/change content by path
	errors         []FMError         // Parse errors encountered
}

// content generates formatted string representation
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

// export writes all FILE content to destination directory
pub fn (mut fm FileMap) export(path string) ! {
	for filepath, filecontent in fm.content {
		dest := '${path}/${filepath}'
		mut filepathtowrite := pathlib.get_file(path: dest, create: true)!
		filepathtowrite.write(filecontent)!
	}
}

@[params]
pub struct WriteParams {
	path        string
	v_test      bool = true
	v_format    bool = true
	python_test bool
}

// write updates files in destination directory (creates or overwrites)
pub fn (mut fm FileMap) write(path string) ! {
	for filepath, filecontent in fm.content {
		dest := '${path}/${filepath}'
		mut filepathtowrite := pathlib.get_file(path: dest, create: true)!
		filepathtowrite.write(filecontent)!
	}
}

// get retrieves file content by path
pub fn (fm FileMap) get(relpath string) !string {
	return fm.content[relpath] or { return error('File not found: ${relpath}') }
}

// set stores file content by path
pub fn (mut fm FileMap) set(relpath string, content string) {
	fm.content[relpath] = content
}

// delete removes file from content map
pub fn (mut fm FileMap) delete(relpath string) {
	fm.content.delete(relpath)
}

// find returns all paths matching prefix
pub fn (fm FileMap) find(path string) []string {
	mut result := []string{}
	for filepath, _ in fm.content {
		if filepath.starts_with(path) {
			result << filepath
		}
	}
	return result
}
