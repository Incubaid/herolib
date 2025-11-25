module filemap

import os
import incubaid.herolib.core.pathlib

fn test_parse_header_file() {
	kind, name := parse_header('===FILE:main.v===')!
	assert kind == BlockKind.file
	assert name == 'main.v'
}

fn test_parse_header_filechange() {
	kind, name := parse_header('===FILECHANGE:utils/helper.v===')!
	assert kind == BlockKind.filechange
	assert name == 'utils/helper.v'
}

fn test_parse_header_end() {
	kind, _ := parse_header('===END===')!
	assert kind == BlockKind.end
}

fn test_parse_header_with_spaces() {
	kind, name := parse_header('  === FILE : config.yaml ===  ')!
	assert kind == BlockKind.file
	assert name == 'config.yaml'
}

fn test_parse_header_lowercase() {
	kind, name := parse_header('===file:test.txt===')!
	assert kind == BlockKind.file
	assert name == 'test.txt'
}

fn test_parse_header_variable_equals() {
	kind, name := parse_header('=FILE:path/file.v=')!
	assert kind == BlockKind.file
	assert name == 'path/file.v'
}

fn test_parse_header_end_lowercase() {
	kind, _ := parse_header('===end===')!
	assert kind == BlockKind.end
}

fn test_filemap_from_simple_content() {
	content := '===FILE:main.v===
fn main() {
	println("Hello, World!")
}
===END==='

	fm := filemap_get_from_content(content)!
	assert fm.content.len == 1
	assert 'main.v' in fm.content
	assert fm.content['main.v'].contains('println')
}

fn test_filemap_from_multiple_files() {
	content := '===FILE:main.v===
fn main() {
	println("Hello")
}
===FILE:utils/helper.v===
pub fn help() {
	println("Helping")
}
===END==='

	fm := filemap_get_from_content(content)!
	assert fm.content.len == 2
	assert 'main.v' in fm.content
	assert 'utils/helper.v' in fm.content
}

fn test_filemap_with_filechange() {
	content := '===FILE:config.v===
pub const version = "1.0"
===FILECHANGE:main.v===
fn main() {
	println(version)
}
===END==='

	fm := filemap_get_from_content(content)!
	assert fm.content.len == 1
	assert fm.content_change.len == 1
	assert 'config.v' in fm.content
	assert 'main.v' in fm.content_change
}

fn test_filemap_multiline_content() {
	content := '===FILE:multiline.txt===
Line 1
Line 2
Line 3
===FILE:another.txt===
Another content
===END==='

	fm := filemap_get_from_content(content)!
	assert fm.content['multiline.txt'].contains('Line 1')
	assert fm.content['multiline.txt'].contains('Line 2')
	assert fm.content['multiline.txt'].contains('Line 3')
	assert fm.content['another.txt'] == 'Another content'
}

fn test_filemap_get_method() {
	content := '===FILE:test.v===
test content
===END==='

	fm := filemap_get_from_content(content)!
	result := fm.get('test.v')!
	assert result == 'test content'
}

fn test_filemap_get_not_found() {
	content := '===FILE:test.v===
content
===END==='

	fm := filemap_get_from_content(content)!
	result := fm.get('nonexistent.v') or {
		assert err.msg().contains('File not found')
		return
	}
	panic('Should have returned error')
}

fn test_filemap_set_method() {
	mut fm := FileMap{}
	fm.set('new/file.v', 'new content')
	assert fm.content['new/file.v'] == 'new content'
}

fn test_filemap_delete_method() {
	mut fm := FileMap{}
	fm.set('file1.v', 'content1')
	fm.set('file2.v', 'content2')
	assert fm.content.len == 2

	fm.delete('file1.v')
	assert fm.content.len == 1
	assert 'file2.v' in fm.content
	assert 'file1.v' !in fm.content
}

fn test_filemap_find_method() {
	mut fm := FileMap{}
	fm.set('src/main.v', 'main')
	fm.set('src/utils/helper.v', 'helper')
	fm.set('test/test.v', 'test')

	results := fm.find('src/')
	assert results.len == 2
	assert 'src/main.v' in results
	assert 'src/utils/helper.v' in results
}

fn test_filemap_find_empty() {
	mut fm := FileMap{}
	fm.set('main.v', 'main')

	results := fm.find('src/')
	assert results.len == 0
}

fn test_filemap_from_path() {
	// Create temporary test directory
	tmpdir := os.temp_dir() + '/test_filemap_${os.getpid()}'
	os.mkdir_all(tmpdir) or { panic(err) }
	defer {
		os.rmdir_all(tmpdir) or {}
	}

	// Create test files
	os.mkdir_all('${tmpdir}/src') or { panic(err) }
	os.mkdir_all('${tmpdir}/test') or { panic(err) }

	os.write_file('${tmpdir}/main.v', 'fn main() {}')!
	os.write_file('${tmpdir}/src/utils.v', 'pub fn help() {}')!
	os.write_file('${tmpdir}/test/test.v', 'fn test() {}')!

	fm := filemap_get_from_path(tmpdir, true)!

	assert fm.content.len >= 3
	assert 'main.v' in fm.content
	assert fm.content['main.v'] == 'fn main() {}'
}

fn test_filemap_from_path_no_content() {
	tmpdir := os.temp_dir() + '/test_filemap_nocontent_${os.getpid()}'
	os.mkdir_all(tmpdir) or { panic(err) }
	defer {
		os.rmdir_all(tmpdir) or {}
	}

	os.mkdir_all('${tmpdir}/src') or { panic(err) }
	os.write_file('${tmpdir}/main.v', 'fn main() {}')!

	fm := filemap_get_from_path(tmpdir, false)!

	assert fm.content.len >= 1
	assert 'main.v' in fm.content
	assert fm.content['main.v'] == ''
}

fn test_filemap_from_path_not_exists() {
	result := filemap_get_from_path('/nonexistent/path/12345', true) or {
		assert err.msg().contains('does not exist')
		return
	}
	panic('Should have returned error for nonexistent path')
}

fn test_filemap_content_string() {
	mut fm := FileMap{}
	fm.set('file1.v', 'content1')
	fm.set('file2.v', 'content2')

	output := fm.content()
	assert output.contains('===FILE:file1.v===')
	assert output.contains('content1')
	assert output.contains('===FILE:file2.v===')
	assert output.contains('content2')
	assert output.contains('===END===')
}

fn test_filemap_export() {
	tmpdir := os.temp_dir() + '/test_filemap_export_${os.getpid()}'
	os.mkdir_all(tmpdir) or { panic(err) }
	defer {
		os.rmdir_all(tmpdir) or {}
	}

	mut fm := FileMap{}
	fm.set('main.v', 'fn main() {}')
	fm.set('src/helper.v', 'pub fn help() {}')

	fm.export(tmpdir)!

	assert os.exists('${tmpdir}/main.v')
	assert os.exists('${tmpdir}/src/helper.v')
	assert os.read_file('${tmpdir}/main.v')! == 'fn main() {}'
}

fn test_filemap_write() {
	tmpdir := os.temp_dir() + '/test_filemap_write_${os.getpid()}'
	os.mkdir_all(tmpdir) or { panic(err) }
	defer {
		os.rmdir_all(tmpdir) or {}
	}

	mut fm := FileMap{}
	fm.set('config.v', 'const version = "1.0"')
	fm.set('models/user.v', 'struct User {}')

	fm.write(tmpdir)!

	assert os.exists('${tmpdir}/config.v')
	assert os.exists('${tmpdir}/models/user.v')
}

fn test_filemap_factory_from_path() {
	tmpdir := os.temp_dir() + '/test_factory_path_${os.getpid()}'
	os.mkdir_all(tmpdir) or { panic(err) }
	defer {
		os.rmdir_all(tmpdir) or {}
	}

	os.write_file('${tmpdir}/test.v', 'fn test() {}')!

	fm := filemap(path: tmpdir, content_read: true)!
	assert 'test.v' in fm.content
}

fn test_filemap_factory_from_content() {
	content := '===FILE:sample.v===
fn main() {}
===END==='

	fm := filemap(content: content)!
	assert 'sample.v' in fm.content
}

fn test_filemap_factory_requires_input() {
	result := filemap(path: '', content: '') or {
		assert err.msg().contains('Either path or content')
		return
	}
	panic('Should have returned error')
}

fn test_filemap_parse_errors_content_before_file() {
	content := 'Some text before file
===FILE:main.v===
content
===END==='

	fm := filemap_get_from_content(content)!
	assert fm.errors.len > 0
	assert fm.errors[0].category == 'parse'
}

fn test_filemap_parse_errors_end_without_file() {
	content := '===END==='

	fm := filemap_get_from_content(content)!
	assert fm.errors.len > 0
}

fn test_filemap_empty_content() {
	content := ''
	fm := filemap_get_from_content(content)!
	assert fm.content.len == 0
}

fn test_filemap_complex_filenames() {
	content := '===FILE:src/v_models/user_model.v===
pub struct User {}
===FILE:test/unit/user_test.v===
fn test_user() {}
===FILE:.config/settings.json===
{ "key": "value" }
===END==='

	fm := filemap_get_from_content(content)!
	assert 'src/v_models/user_model.v' in fm.content
	assert 'test/unit/user_test.v' in fm.content
	assert '.config/settings.json' in fm.content
}

fn test_filemap_whitespace_preservation() {
	content := '===FILE:formatted.txt===
Line with    spaces
	Tab indented
  Spaces indented
===END==='

	fm := filemap_get_from_content(content)!
	file_content := fm.content['formatted.txt']
	assert file_content.contains('    spaces')
	assert file_content.contains('\t')
}
