module codewalker

import os
import freeflowuniverse.herolib.core.pathlib

fn test_parse_basic() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '===FILE:file1.txt===\nline1\nline2\n===END==='
	fm := cw.parse(test_content)!
	assert fm.content.len == 1
	assert fm.content['file1.txt'] == 'line1\nline2'
}

fn test_parse_multiple_files() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '===FILE:file1.txt===\nline1\n===FILE:file2.txt===\nlineA\nlineB\n===END==='
	fm := cw.parse(test_content)!
	assert fm.content.len == 2
	assert fm.content['file1.txt'] == 'line1'
	assert fm.content['file2.txt'] == 'lineA\nlineB'
}

fn test_parse_empty_file_block() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '===FILE:empty.txt===\n===END==='
	fm := cw.parse(test_content)!
	assert fm.content.len == 1
	assert fm.content['empty.txt'] == ''
}

fn test_parse_consecutive_end_and_file() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '===FILE:file1.txt===\ncontent1\n===END===\n===FILE:file2.txt===\ncontent2\n===END==='
	fm := cw.parse(test_content)!
	assert fm.content.len == 2
	assert fm.content['file1.txt'] == 'content1'
	assert fm.content['file2.txt'] == 'content2'
}

fn test_parse_content_before_first_file_block() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := 'unexpected content\n===FILE:file1.txt===\ncontent\n===END==='
	// This should ideally log an error but still parse the file
	fm := cw.parse(test_content)!
	assert fm.content.len == 1
	assert fm.content['file1.txt'] == 'content'
	assert cw.errors.len > 0
	assert cw.errors[0].message.contains('Unexpected content before first file block')
}

fn test_parse_content_after_end() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '===FILE:file1.txt===\ncontent\n===END===\nmore unexpected content'
	// Implementation chooses to ignore content after END but return parsed content
	fm := cw.parse(test_content)!
	assert fm.content.len == 1
	assert fm.content['file1.txt'] == 'content'
}

fn test_parse_invalid_filename_line() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '======\ncontent\n===END==='
	cw.parse(test_content) or {
		assert err.msg().contains('Invalid filename, < 1 chars')
		return
	}
	assert false // Should have errored
}

fn test_parse_file_ending_without_end() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '===FILE:file1.txt===\nline1\nline2'
	fm := cw.parse(test_content)!
	assert fm.content.len == 1
	assert fm.content['file1.txt'] == 'line1\nline2'
}

fn test_parse_empty_content() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := ''
	fm := cw.parse(test_content)!
	assert fm.content.len == 0
}

fn test_parse_only_end_at_start() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '===END==='
	cw.parse(test_content) or {
		assert err.msg().contains('END found at start, not good.')
		return
	}
	assert false // Should have errored
}

fn test_parse_mixed_file_and_filechange() {
	mut cw2 := new(CodeWalkerArgs{})!
	test_content2 := '===FILE:file.txt===\nfull\n===FILECHANGE:file.txt===\npartial\n===END==='
	fm2 := cw2.parse(test_content2)!
	assert fm2.content.len == 1
	assert fm2.content_change.len == 1
	assert fm2.content['file.txt'] == 'full'
	assert fm2.content_change['file.txt'] == 'partial'
}

fn test_parse_empty_block_between_files() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '===FILE:file1.txt===\ncontent1\n===FILE:file2.txt===\n===END===\n===FILE:file3.txt===\ncontent3\n===END==='
	fm := cw.parse(test_content)!
	assert fm.content.len == 3
	assert fm.content['file1.txt'] == 'content1'
	assert fm.content['file2.txt'] == ''
	assert fm.content['file3.txt'] == 'content3'
}

fn test_parse_multiple_empty_blocks() {
	mut cw := new(CodeWalkerArgs{})!
	test_content := '===FILE:file1.txt===\n===END===\n===FILE:file2.txt===\n===END===\n===FILE:file3.txt===\ncontent3\n===END==='
	fm := cw.parse(test_content)!
	assert fm.content.len == 3
	assert fm.content['file1.txt'] == ''
	assert fm.content['file2.txt'] == ''
	assert fm.content['file3.txt'] == 'content3'
}

fn test_parse_filename_end_reserved() {
	mut cw := new(CodeWalkerArgs{})!
	// Legacy header 'END' used as filename should error when used as header for new block
	test_content := '===file1.txt===\ncontent1\n===END===\n===END===\ncontent2\n===END==='
	cw.parse(test_content) or {
		assert err.msg().contains("Filename 'END' is reserved.")
		return
	}
	assert false // Should have errored
}

fn test_filemap_export_and_write() ! {
	// Setup temp dir
	mut tmpdir := pathlib.get_dir(
		path:   os.join_path(os.temp_dir(), 'cw_test')
		create: true
		empty:  true
	)!
	defer {
		tmpdir.delete() or {}
	}
	// Build a FileMap
	mut fm := FileMap{
		source: tmpdir.path
	}
	fm.set('a/b.txt', 'hello')
	fm.set('c.txt', 'world')
	// Export to new dir
	mut dest := pathlib.get_dir(
		path:   os.join_path(os.temp_dir(), 'cw_out')
		create: true
		empty:  true
	)!
	defer {
		dest.delete() or {}
	}
	fm.export(dest.path)!
	mut f1 := pathlib.get_file(path: os.join_path(dest.path, 'a/b.txt'))!
	mut f2 := pathlib.get_file(path: os.join_path(dest.path, 'c.txt'))!
	assert f1.read()! == 'hello'
	assert f2.read()! == 'world'
	// Overwrite via write()
	fm.set('a/b.txt', 'hello2')
	fm.write(dest.path)!
	assert f1.read()! == 'hello2'
}

fn test_filemap_content_roundtrip() {
	mut fm := FileMap{}
	fm.set('x.txt', 'X')
	fm.content_change['y.txt'] = 'Y'
	txt := fm.content()
	assert txt.contains('===FILE:x.txt===')
	assert txt.contains('===FILECHANGE:y.txt===')
	assert txt.contains('===END===')
}

fn test_ignore_level_scoped() ! {
	// create temp dir structure
	mut root := pathlib.get_dir(
		path:   os.join_path(os.temp_dir(), 'cw_ign_lvl')
		create: true
		empty:  true
	)!
	defer { root.delete() or {} }
	// subdir with its own ignore
	mut sub := pathlib.get_dir(path: os.join_path(root.path, 'sub'), create: true)!
	mut hero := pathlib.get_file(path: os.join_path(sub.path, '.heroignore'), create: true)!
	hero.write('dist/\n')!
	// files under sub/dist should be ignored
	mut dist := pathlib.get_dir(path: os.join_path(sub.path, 'dist'), create: true)!
	mut a1 := pathlib.get_file(path: os.join_path(dist.path, 'a.txt'), create: true)!
	a1.write('A')!
	// sibling sub2 with a dist, should NOT be ignored by sub's .heroignore
	mut sub2 := pathlib.get_dir(path: os.join_path(root.path, 'sub2'), create: true)!
	mut dist2 := pathlib.get_dir(path: os.join_path(sub2.path, 'dist'), create: true)!
	mut b1 := pathlib.get_file(path: os.join_path(dist2.path, 'b.txt'), create: true)!
	b1.write('B')!
	// a normal file under sub should be included
	mut okf := pathlib.get_file(path: os.join_path(sub.path, 'ok.txt'), create: true)!
	okf.write('OK')!

	mut cw := new(CodeWalkerArgs{})!
	mut fm := cw.filemap_get(path: root.path)!

	// sub/dist/a.txt should be ignored
	assert 'sub/dist/a.txt' !in fm.content.keys()
	// sub/ok.txt should be included
	assert fm.content['sub/ok.txt'] == 'OK'
	// sub2/dist/b.txt should be included (since .heroignore is level-scoped)
	assert fm.content['sub2/dist/b.txt'] == 'B'
}

fn test_ignore_level_scoped_gitignore() ! {
	mut root := pathlib.get_dir(
		path:   os.join_path(os.temp_dir(), 'cw_ign_git')
		create: true
		empty:  true
	)!
	defer { root.delete() or {} }
	// root has .gitignore ignoring logs/
	mut g := pathlib.get_file(path: os.join_path(root.path, '.gitignore'), create: true)!
	g.write('logs/\n')!
	// nested structure
	mut svc := pathlib.get_dir(path: os.join_path(root.path, 'svc'), create: true)!
	// this logs/ should be ignored due to root .gitignore
	mut logs := pathlib.get_dir(path: os.join_path(svc.path, 'logs'), create: true)!
	mut out := pathlib.get_file(path: os.join_path(logs.path, 'out.txt'), create: true)!
	out.write('ignored')!
	// regular file should be included
	mut appf := pathlib.get_file(path: os.join_path(svc.path, 'app.txt'), create: true)!
	appf.write('app')!

	mut cw := new(CodeWalkerArgs{})!
	mut fm := cw.filemap_get(path: root.path)!
	assert 'svc/logs/out.txt' !in fm.content.keys()
	assert fm.content['svc/app.txt'] == 'app'
}

fn test_parse_filename_end_reserved_legacy() {
	mut cw := new(CodeWalkerArgs{})!
	// Legacy header 'END' used as filename should error when used as header for new block
	test_content := '===file1.txt===\ncontent1\n===END===\n===END===\ncontent2\n===END==='
	cw.parse(test_content) or {
		assert err.msg().contains("Filename 'END' is reserved.")
		return
	}
	assert false // Should have errored
}
