module webdav

import incubaid.herolib.vfs.vfs_db
import incubaid.herolib.data.ourdb
import encoding.xml
import os
import time
import veb
import net.http
import log

fn testsuite_begin() {
	log.set_level(.debug)
}

const testdata_path = os.join_path(os.dir(@FILE), 'testdata')
const database_path = os.join_path(testdata_path, 'database')

// Helper function to create a test server and DatabaseVFS
fn setup_test_server(function string) !(&vfs_db.DatabaseVFS, &Server) {
	if !os.exists(testdata_path) {
		os.mkdir_all(testdata_path) or {
			return error('Failed to create testdata directory: ${err}')
		}
	}
	if !os.exists(database_path) {
		os.mkdir_all(database_path) or {
			return error('Failed to create database directory: ${err}')
		}
	}

	mut metadata_db := ourdb.new(path: os.join_path(database_path, '${function}/metadata'))!
	mut data_db := ourdb.new(path: os.join_path(database_path, '${function}/data'))!
	mut vfs := vfs_db.new(mut metadata_db, mut data_db)!

	// Create a test server
	mut server := new_server(
		vfs:     vfs
		user_db: {
			'admin': '123'
		}
	)!

	return vfs, server
}

// Helper function to create a test file in the DatabaseVFS
fn create_test_file(mut vfs vfs_db.DatabaseVFS, path string, content string) ! {
	vfs.file_write(path, content.bytes())!
}

// Helper function to create a test directory in the DatabaseVFS
fn create_test_directory(mut vfs vfs_db.DatabaseVFS, path string) ! {
	vfs.dir_create(path)!
}

fn test_server_run() ! {
	_, mut server := setup_test_server(@FILE)!
	spawn server.run()
	time.sleep(100 * time.millisecond)
}

fn test_server_index() ! {
	_, mut server := setup_test_server(@FILE)!

	mut ctx := Context{
		req: http.Request{
			method: http.Method.head
			url:    '/'
		}
		res: http.Response{}
	}

	server.index(mut ctx)

	assert ctx.res.status() == http.Status.ok
	assert ctx.res.header.get_custom('DAV')! == '1,2'
	assert ctx.res.header.get(.allow)! == 'OPTIONS, PROPFIND, MKCOL, GET, HEAD, POST, PUT, DELETE, COPY, MOVE'
	assert ctx.res.header.get_custom('MS-Author-Via')! == 'DAV'
	assert ctx.res.header.get(.access_control_allow_origin)! == '*'
	assert ctx.res.header.get(.access_control_allow_methods)! == 'OPTIONS, PROPFIND, MKCOL, GET, HEAD, POST, PUT, DELETE, COPY, MOVE'
	assert ctx.res.header.get(.access_control_allow_headers)! == 'Authorization, Content-Type'
	assert ctx.res.header.get(.content_length)! == '0'
}

fn test_server_options() ! {
	_, mut server := setup_test_server(@FILE)!

	mut ctx := Context{
		req: http.Request{
			method: http.Method.options
			url:    '/test_path'
		}
		res: http.Response{}
	}

	server.options(mut ctx, 'test_path')

	assert ctx.res.status() == http.Status.ok
	assert ctx.res.header.get_custom('DAV')! == '1,2'
	assert ctx.res.header.get(.allow)! == 'OPTIONS, PROPFIND, MKCOL, GET, HEAD, POST, PUT, DELETE, COPY, MOVE'
	assert ctx.res.header.get_custom('MS-Author-Via')! == 'DAV'
	assert ctx.res.header.get(.access_control_allow_origin)! == '*'
	assert ctx.res.header.get(.access_control_allow_methods)! == 'OPTIONS, PROPFIND, MKCOL, GET, HEAD, POST, PUT, DELETE, COPY, MOVE'
	assert ctx.res.header.get(.access_control_allow_headers)! == 'Authorization, Content-Type'
	assert ctx.res.header.get(.content_length)! == '0'
}

fn test_server_lock() ! {
	_, mut server := setup_test_server(@FILE)!

	// Create a test file to lock
	test_path := 'test_lock_file.txt'

	// Prepare lock XML request body
	lock_xml := '<?xml version="1.0" encoding="utf-8"?>
<D:lockinfo xmlns:D="DAV:">
  <D:lockscope><D:exclusive/></D:lockscope>
  <D:locktype><D:write/></D:locktype>
  <D:owner>
    <D:href>test-user</D:href>
  </D:owner>
</D:lockinfo>'

	mut ctx := Context{
		req: http.Request{
			method: http.Method.lock
			url:    '/${test_path}'
			data:   lock_xml
			header: http.Header{}
		}
		res: http.Response{}
	}

	// Set headers
	ctx.req.header.add_custom('Depth', '0')!
	ctx.req.header.add_custom('Timeout', 'Second-3600')!

	server.lock(mut ctx, test_path)

	// Check response
	assert ctx.res.status() == http.Status.ok
	assert ctx.res.header.get_custom('Lock-Token')! != ''
	assert ctx.res.header.get(.content_type)! == 'application/xml'

	// Verify response contains proper lock XML
	assert ctx.res.body.len > 0
	assert ctx.res.body.contains('<D:lockdiscovery')
	assert ctx.res.body.contains('<D:activelock>')
}

fn test_server_unlock() ! {
	_, mut server := setup_test_server(@FILE)!

	// Create a test file
	test_path := 'test_unlock_file.txt'

	// First lock the resource
	lock_xml := '<?xml version="1.0" encoding="utf-8"?>
<D:lockinfo xmlns:D="DAV:">
  <D:lockscope><D:exclusive/></D:lockscope>
  <D:locktype><D:write/></D:locktype>
  <D:owner>
    <D:href>test-user</D:href>
  </D:owner>
</D:lockinfo>'

	mut lock_ctx := Context{
		req: http.Request{
			method: http.Method.lock
			url:    '/${test_path}'
			data:   lock_xml
			header: http.Header{}
		}
		res: http.Response{}
	}

	lock_ctx.req.header.add_custom('Depth', '0')!
	lock_ctx.req.header.add_custom('Timeout', 'Second-3600')!

	server.lock(mut lock_ctx, test_path)

	// Extract lock token from response
	lock_token := lock_ctx.res.header.get_custom('Lock-Token')!

	// Now unlock the resource
	mut unlock_ctx := Context{
		req: http.Request{
			method: http.Method.unlock
			url:    '/${test_path}'
			header: http.Header{}
		}
		res: http.Response{}
	}

	unlock_ctx.req.header.add_custom('Lock-Token', lock_token)!

	server.unlock(mut unlock_ctx, test_path)

	// Check response
	assert unlock_ctx.res.status() == http.Status.no_content
}

fn test_server_get_file() ! {
	mut vfs, mut server := setup_test_server(@FN)!

	// Create a test file
	test_path := 'test_get_file.txt'
	test_content := 'This is a test file content'
	create_test_file(mut vfs, test_path, test_content)!

	mut ctx := Context{
		req: http.Request{
			method: http.Method.get
			url:    '/${test_path}'
		}
		res: http.Response{}
	}

	server.get_file(mut ctx, test_path)

	// Check response
	assert ctx.res.status() == http.Status.ok
	assert ctx.res.header.get(.content_type)! == 'text/plain'
	assert ctx.res.body == test_content
}

fn test_server_exists() ! {
	mut vfs, mut server := setup_test_server(@FILE)!

	// Create a test file
	test_path := 'test_exists_file.txt'
	test_content := 'This is a test file content'
	create_test_file(mut vfs, test_path, test_content)!

	// Test for existing file
	mut ctx := Context{
		req: http.Request{
			method: http.Method.head
			url:    '/${test_path}'
		}
		res: http.Response{}
	}

	server.exists(mut ctx, test_path)

	// Check response for existing file
	assert ctx.res.status() == http.Status.ok
	assert ctx.res.header.get_custom('dav')! == '1, 2'
	assert ctx.res.header.get(.content_length)! == '0'
	assert ctx.res.header.get_custom('Allow')!.contains('OPTIONS')
	assert ctx.res.header.get(.accept_ranges)! == 'bytes'

	// Test for non-existing file
	mut ctx2 := Context{
		req: http.Request{
			method: http.Method.head
			url:    '/nonexistent_file.txt'
		}
		res: http.Response{}
	}

	server.exists(mut ctx2, 'nonexistent_file.txt')

	// Check response for non-existing file
	assert ctx2.res.status() == http.Status.not_found
}

fn test_server_delete() ! {
	mut vfs, mut server := setup_test_server(@FILE)!

	// Create a test file
	test_path := 'test_delete_file.txt'
	test_content := 'This is a test file to delete'
	create_test_file(mut vfs, test_path, test_content)!

	// Verify file exists
	assert vfs.exists(test_path)

	mut ctx := Context{
		req: http.Request{
			method: http.Method.delete
			url:    '/${test_path}'
		}
		res: http.Response{}
	}

	server.delete(mut ctx, test_path)

	// Check response
	assert ctx.res.status() == http.Status.no_content

	// Verify file was deleted
	assert !vfs.exists(test_path)
}

fn test_server_copy() ! {
	mut vfs, mut server := setup_test_server(@FILE)!

	// Create a test file
	source_path := 'test_copy_source.txt'
	dest_path := 'test_copy_dest.txt'
	test_content := 'This is a test file to copy'
	create_test_file(mut vfs, source_path, test_content)!

	mut ctx := Context{
		req: http.Request{
			method: http.Method.copy
			url:    '/${source_path}'
			header: http.Header{}
		}
		res: http.Response{}
	}

	// Set Destination header
	ctx.req.header.add_custom('Destination', 'http://localhost/${dest_path}')!
	log.set_level(.debug)
	server.copy(mut ctx, source_path)

	// Check response
	assert ctx.res.status() == http.Status.ok

	// Verify destination file exists and has the same content
	assert vfs.exists(dest_path)
	dest_content := vfs.file_read(dest_path) or { panic(err) }
	assert dest_content.bytestr() == test_content
}

fn test_server_move() ! {
	mut vfs, mut server := setup_test_server(@FILE)!

	// Create a test file
	source_path := 'test_move_source.txt'
	dest_path := 'test_move_dest.txt'
	test_content := 'This is a test file to move'
	create_test_file(mut vfs, source_path, test_content)!

	mut ctx := Context{
		req: http.Request{
			method: http.Method.move
			url:    '/${source_path}'
			header: http.Header{}
		}
		res: http.Response{}
	}

	// Set Destination header
	ctx.req.header.add_custom('Destination', 'http://localhost/${dest_path}')!

	server.move(mut ctx, source_path)

	// Check response
	assert ctx.res.status() == http.Status.ok

	// Verify source file no longer exists
	assert !vfs.exists(source_path)

	// Verify destination file exists and has the same content
	assert vfs.exists(dest_path)
	dest_content := vfs.file_read(dest_path) or { panic(err) }
	assert dest_content.bytestr() == test_content
}

fn test_server_mkcol() ! {
	mut vfs, mut server := setup_test_server(@FILE)!

	// Test directory path
	test_dir := 'test_mkcol_dir'

	mut ctx := Context{
		req: http.Request{
			method: http.Method.mkcol
			url:    '/${test_dir}'
		}
		res: http.Response{}
	}

	server.mkcol(mut ctx, test_dir)

	// Check response
	assert ctx.res.status() == http.Status.created

	// Verify directory was created
	assert vfs.exists(test_dir)
	dir_entry := vfs.get(test_dir) or { panic(err) }
	assert dir_entry.is_dir()

	// Test creating a collection that already exists
	mut ctx2 := Context{
		req: http.Request{
			method: http.Method.mkcol
			url:    '/${test_dir}'
		}
		res: http.Response{}
	}

	server.mkcol(mut ctx2, test_dir)

	// Should return bad request for existing collection
	assert ctx2.res.status() == http.Status.bad_request
}

fn test_server_put() ! {
	mut vfs, mut server := setup_test_server(@FILE)!

	// Test file path
	test_file := 'test_put_file.txt'
	test_content := 'This is content for PUT test'

	mut ctx := Context{
		req: http.Request{
			method: http.Method.put
			url:    '/${test_file}'
			data:   test_content
		}
		res: http.Response{}
	}

	server.create_or_update(mut ctx, test_file)

	// Check response
	assert ctx.res.status() == http.Status.ok

	// Verify file was created with correct content
	assert vfs.exists(test_file)
	file_content := vfs.file_read(test_file) or { panic(err) }
	assert file_content.bytestr() == test_content

	// Test updating existing file
	new_content := 'Updated content for PUT test'
	mut ctx2 := Context{
		req: http.Request{
			method: http.Method.put
			url:    '/${test_file}'
			data:   new_content
		}
		res: http.Response{}
	}

	server.create_or_update(mut ctx2, test_file)

	// Check response
	assert ctx2.res.status() == http.Status.ok

	// Verify file was updated with new content
	updated_content := vfs.file_read(test_file) or { panic(err) }
	assert updated_content.bytestr() == new_content
}

fn test_server_propfind() ! {
	mut vfs, mut server := setup_test_server(@FILE)!

	// Create test directory and file structure
	root_dir := 'propfind_test'
	file_in_root := '${root_dir}/test_file.txt'
	subdir := '${root_dir}/subdir'
	file_in_subdir := '${subdir}/subdir_file.txt'

	create_test_directory(mut vfs, root_dir)!
	create_test_file(mut vfs, file_in_root, 'Test file content')!
	create_test_directory(mut vfs, subdir)!
	create_test_file(mut vfs, file_in_subdir, 'Subdir file content')!

	// Test PROPFIND with depth=0 (just the resource)
	propfind_xml := '<?xml version="1.0" encoding="utf-8"?>
<D:propfind xmlns:D="DAV:">
  <D:allprop/>
</D:propfind>'

	mut ctx := Context{
		req: http.Request{
			method: http.Method.propfind
			url:    '/${root_dir}'
			data:   propfind_xml
			header: http.Header{}
		}
		res: http.Response{}
	}

	// Set Depth header to 0
	ctx.req.header.add_custom('Depth', '0')!

	server.propfind(mut ctx, root_dir)

	// Check response
	assert ctx.res.status() == http.Status.multi_status
	assert ctx.res.header.get(.content_type)! == 'application/xml'
	assert ctx.res.body.contains('<D:multistatus')
	assert ctx.res.body.contains('<D:response>')

	// Now that we know the correct format, check for it - directories have both leading and trailing slashes
	assert ctx.res.body.contains('<D:href>/${root_dir}/</D:href>')
	// Should only include the requested resource
	assert !ctx.res.body.contains('<D:href>/${file_in_root}</D:href>')
		&& !ctx.res.body.contains('<D:href>/${file_in_root}')

	// Test PROPFIND with depth=1 (resource and immediate children)
	mut ctx2 := Context{
		req: http.Request{
			method: http.Method.propfind
			url:    '/${root_dir}'
			data:   propfind_xml
			header: http.Header{}
		}
		res: http.Response{}
	}

	// Set Depth header to 1
	ctx2.req.header.add_custom('Depth', '1')!

	server.propfind(mut ctx2, root_dir)

	// Check response
	assert ctx2.res.status() == http.Status.multi_status
	assert ctx2.res.body.contains('<D:multistatus')
	// Should include the resource and immediate children
	assert ctx2.res.body.contains('<D:href>/${root_dir}/</D:href>')
	assert ctx2.res.body.contains('<D:href>/${file_in_root}</D:href>')
	assert ctx2.res.body.contains('<D:href>/${subdir}/</D:href>')
	// But not grandchildren
	assert !ctx2.res.body.contains('<D:href>/${file_in_subdir}</D:href>')

	// Test PROPFIND with depth=infinity (all descendants)
	mut ctx3 := Context{
		req: http.Request{
			method: http.Method.propfind
			url:    '/${root_dir}'
			data:   propfind_xml
			header: http.Header{}
		}
		res: http.Response{}
	}

	// Set Depth header to infinity
	ctx3.req.header.add_custom('Depth', 'infinity')!

	server.propfind(mut ctx3, root_dir)

	// Check response
	assert ctx3.res.status() == http.Status.multi_status
	// Should include all descendants
	assert ctx3.res.body.contains('<D:href>/${root_dir}/</D:href>')
	assert ctx3.res.body.contains('<D:href>/${file_in_root}</D:href>')
	assert ctx3.res.body.contains('<D:href>/${subdir}/</D:href>')
	assert ctx3.res.body.contains('<D:href>/${file_in_subdir}</D:href>')

	// Test PROPFIND for non-existent resource
	mut ctx4 := Context{
		req: http.Request{
			method: http.Method.propfind
			url:    '/nonexistent'
			data:   propfind_xml
			header: http.Header{}
		}
		res: http.Response{}
	}

	ctx4.req.header.add_custom('Depth', '0')!

	server.propfind(mut ctx4, 'nonexistent')

	// Should return not found
	assert ctx4.res.status() == http.Status.not_found
}
