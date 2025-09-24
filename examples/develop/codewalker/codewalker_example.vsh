#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.develop.codewalker
import freeflowuniverse.herolib.core.pathlib
import os

// Simple example demonstrating CodeWalker:
// - Build a FileMap from a directory (respecting .gitignore)
// - Serialize to filemap text
// - Export to a different destination
// - Parse filemap text directly

// 1) Prepare a small temp source directory
mut srcdir := pathlib.get_dir(
	path:   os.join_path(os.temp_dir(), 'codewalker_example_src')
	create: true
	empty:  true
)!

// Create some files
mut f1 := pathlib.get_file(path: os.join_path(srcdir.path, 'a/b.txt'), create: true)!
f1.write('hello from a/b.txt')!
mut f2 := pathlib.get_file(path: os.join_path(srcdir.path, 'c.txt'), create: true)!
f2.write('world from c.txt')!

// Create ignored files and a .gitignore
mut ig := pathlib.get_file(path: os.join_path(srcdir.path, '.gitignore'), create: true)!
ig.write('__pycache__/\n*.pyc\nbuild/\n')!

mut ignored_dir := pathlib.get_dir(path: os.join_path(srcdir.path, '__pycache__'), create: true)!
_ = ignored_dir // not used

mut ignored_file := pathlib.get_file(path: os.join_path(srcdir.path, 'script.pyc'), create: true)!
ignored_file.write('ignored bytecode')!

mut ignored_build := pathlib.get_dir(path: os.join_path(srcdir.path, 'build'), create: true)!
mut ignored_in_build := pathlib.get_file(
	path:   os.join_path(ignored_build.path, 'temp.bin')
	create: true
)!
ignored_in_build.write('ignored build artifact')!

// Demonstrate level-scoped .heroignore
mut lvl := pathlib.get_dir(path: os.join_path(srcdir.path, 'test_gitignore_levels'), create: true)!
mut hero := pathlib.get_file(path: os.join_path(lvl.path, '.heroignore'), create: true)!
hero.write('dist/\n')!
// files under test_gitignore_levels/dist should be ignored (level-scoped)
mut dist := pathlib.get_dir(path: os.join_path(lvl.path, 'dist'), create: true)!
mut cachef := pathlib.get_file(path: os.join_path(dist.path, 'cache.test'), create: true)!
cachef.write('cache here any text')!
mut buildf := pathlib.get_file(path: os.join_path(dist.path, 'build.test'), create: true)!
buildf.write('just build text')!
// sibling tests folder should be included
mut tests := pathlib.get_dir(path: os.join_path(lvl.path, 'tests'), create: true)!
mut testf := pathlib.get_file(path: os.join_path(tests.path, 'file.test'), create: true)!
testf.write('print test is ok for now')!

// 2) Walk the directory into a FileMap (ignored files should be skipped)
mut cw := codewalker.new()!
mut fm := cw.filemap_get(path: srcdir.path)!

println('Collected files: ${fm.content.len}')
for k, _ in fm.content {
	println(' - ${k}')
}

// 3) Serialize to filemap text (for LLMs or storage)
serialized := fm.content()
println('\nSerialized filemap:')
println(serialized)

// 4) Export to a new destination directory
mut destdir := pathlib.get_dir(
	path:   os.join_path(os.temp_dir(), 'codewalker_example_out')
	create: true
	empty:  true
)!
fm.export(destdir.path)!
println('\nExported to: ${destdir.path}')

// 5) Demonstrate direct parsing from filemap text
mut cw2 := codewalker.new(codewalker.CodeWalkerArgs{})!
parsed := cw2.parse(serialized)!
println('\nParsed back from text, files: ${parsed.content.len}')
for k, _ in parsed.content {
	println(' * ${k}')
}
