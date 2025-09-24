#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.lib.lang.codewalker
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.osal.core as osal

// Create test directory structure in /tmp/filemap
test_source := '/tmp/filemap'
test_destination := '/tmp/filemap2'

// Clean up any existing test directories
osal.rm(todelete: test_source)!
osal.rm(todelete: test_destination)!

// Create source directory
mut source_dir := pathlib.get(test_source)!
source_dir.dir_ensure()!

// Create test files with content
mut file1 := source_dir.join('file1.txt')!
file1.write('Content of file 1')!

mut subdir := source_dir.join('subdir')!
subdir.dir_ensure()!

mut file2 := subdir.join('file2.txt')!
file2.write('Content of file 2')!

mut file3 := subdir.join('file3.md')!
file3.write('# Markdown file content')!

println('Test files created in ${test_source}')

// Create CodeWalker instance
mut cw := codewalker.new(name: 'test', source: test_source)!

// Verify files are in the map
println('\nFiles in filemap:')
cw.filemap.write()

// Export files to destination
cw.filemap.export(test_destination)!

println('\nFiles exported to ${test_destination}')

// Verify export by listing files in destination
mut dest_dir := pathlib.get(test_destination)!
if dest_dir.exists() {
	mut files := dest_dir.list(recursive: true)!
	println('\nFiles in destination directory:')
	for file in files {
		if file.is_file() {
			println('  ${file.path}')
			println('    Content: ${file.read()!}')
		}
	}
	println('\nExport test completed successfully!')
} else {
	println('\nError: Destination directory was not created')
}
