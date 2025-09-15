module herofs

import freeflowuniverse.herolib.hero.db

fn test_basic_find() {
	println('Testing FsTools find functionality...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!
	println('HeroFS factory initialized')

	// Create a new filesystem
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem_find'
		description: 'Filesystem for testing FsTools find functionality'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_id := fs_factory.fs.set(my_fs)!
	println('Created test filesystem with ID: ${fs_id}')

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       fs_id
		parent_id:   0 // Root has no parent
		description: 'Root directory for testing find'
	)!

	// Save the root directory
	root_dir_id := fs_factory.fs_dir.set(root_dir)!
	println('Created root directory with ID: ${root_dir_id}')

	// Update the filesystem with the root directory ID
	println('DEBUG: Before update, my_fs.root_dir_id = ${my_fs.root_dir_id}')
	println('DEBUG: Before update, my_fs.id = ${my_fs.id}')
	my_fs.root_dir_id = root_dir_id
	my_fs.id = fs_id // Set the ID to ensure we update the existing object
	println('DEBUG: Setting my_fs.root_dir_id to ${root_dir_id}')
	mut fs_id2 := fs_factory.fs.set(my_fs)!
	println('DEBUG: After update, fs_id2 = ${fs_id2}')
	println('DEBUG: After update, my_fs.root_dir_id = ${my_fs.root_dir_id}')

	// Retrieve the updated filesystem object
	my_fs = fs_factory.fs.get(fs_id)!
	println('DEBUG: After retrieval, fs.root_dir_id = ${my_fs.root_dir_id}')

	// Create test directories
	mut dir1 := fs_factory.fs_dir.new(
		name:        'documents'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Documents directory'
	)!
	dir1_id := fs_factory.fs_dir.set(dir1)!

	mut dir2 := fs_factory.fs_dir.new(
		name:        'images'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Images directory'
	)!
	dir2_id := fs_factory.fs_dir.set(dir2)!

	mut dir3 := fs_factory.fs_dir.new(
		name:        'subdir'
		fs_id:       fs_id
		parent_id:   dir1_id
		description: 'Subdirectory in documents'
	)!
	dir3_id := fs_factory.fs_dir.set(dir3)!

	// Update parent directories with their children
	// Update root_dir to include dir1 and dir2
	println('DEBUG: Updating root_dir with children')
	root_dir.directories = [dir1_id, dir2_id]
	root_dir.id = root_dir_id // Set the ID to ensure we update the existing object
	mut root_dir_id2 := fs_factory.fs_dir.set(root_dir)!
	println('DEBUG: root_dir updated with ID ${root_dir_id2}')

	// Update dir1 to include dir3
	println('DEBUG: Updating dir1 with children')
	dir1.directories = [dir3_id]
	dir1.id = dir1_id // Set the ID to ensure we update the existing object
	mut dir1_id2 := fs_factory.fs_dir.set(dir1)!
	println('DEBUG: dir1 updated with ID ${dir1_id2}')

	// Create test blobs for files
	mut test_blob1 := fs_factory.fs_blob.new(
		data: 'This is test content for file 1'.bytes()
	)!
	blob1_id := fs_factory.fs_blob.set(test_blob1)!
	println('Created test blob with ID: ${blob1_id}')

	mut test_blob2 := fs_factory.fs_blob.new(
		data: 'This is test content for file 2'.bytes()
	)!
	blob2_id := fs_factory.fs_blob.set(test_blob2)!
	println('Created test blob with ID: ${blob2_id}')

	mut test_blob3 := fs_factory.fs_blob.new(
		data: 'This is test content for file 3'.bytes()
	)!
	blob3_id := fs_factory.fs_blob.set(test_blob3)!
	println('Created test blob with ID: ${blob3_id}')

	// Create test files
	mut file1 := fs_factory.fs_file.new(
		name:        'document.txt'
		fs_id:       fs_id
		directories: [dir1_id]
		blobs:       [blob1_id]
		description: 'Text document'
		mime_type:   .txt
	)!
	file1_id := fs_factory.fs_file.set(file1)!

	mut file2 := fs_factory.fs_file.new(
		name:        'image.png'
		fs_id:       fs_id
		directories: [dir2_id]
		blobs:       [blob2_id]
		description: 'PNG image'
		mime_type:   .png
	)!
	file2_id := fs_factory.fs_file.set(file2)!

	mut file3 := fs_factory.fs_file.new(
		name:        'subfile.txt'
		fs_id:       fs_id
		directories: [dir3_id]
		blobs:       [blob3_id]
		description: 'Text file in subdirectory'
		mime_type:   .txt
	)!
	file3_id := fs_factory.fs_file.set(file3)!

	// Create symlinks
	mut symlink1 := fs_factory.fs_symlink.new(
		name:        'doc_link.txt'
		fs_id:       fs_id
		parent_id:   root_dir_id
		target_id:   file1_id
		target_type: .file
		description: 'Symlink to document.txt'
	)!
	symlink1_id := fs_factory.fs_symlink.set(symlink1)!

	mut symlink2 := fs_factory.fs_symlink.new(
		name:        'images_link'
		fs_id:       fs_id
		parent_id:   root_dir_id
		target_id:   dir2_id
		target_type: .directory
		description: 'Symlink to images directory'
	)!
	symlink2_id := fs_factory.fs_symlink.set(symlink2)!

	// Update directories with their children
	// Update dir1 to include dir3 and file1
	dir1.directories = [dir3_id]
	dir1.files = [file1_id]
	fs_factory.fs_dir.set(dir1)!

	// Update dir2 to include file2
	dir2.files = [file2_id]
	fs_factory.fs_dir.set(dir2)!

	// Update dir3 to include file3
	dir3.files = [file3_id]
	dir3.id = dir3_id // Set the ID to ensure we update the existing object
	fs_factory.fs_dir.set(dir3)!

	// Update root_dir to include dir1, dir2, symlink1, symlink2
	root_dir.directories = [dir1_id, dir2_id]
	root_dir.symlinks = [symlink1_id, symlink2_id]
	fs_factory.fs_dir.set(root_dir)!

	println('Created test directory structure:')
	println('- root (ID: ${root_dir_id})')
	println('  - documents (ID: ${dir1_id})')
	println('    - subdir (ID: ${dir3_id})')
	println('      - subfile.txt (ID: ${file3_id})')
	println('    - document.txt (ID: ${file1_id})')
	println('  - images (ID: ${dir2_id})')
	println('    - image.png (ID: ${file2_id})')
	println('  - doc_link.txt (ID: ${symlink1_id}) -> document.txt')
	println('  - images_link (ID: ${symlink2_id}) -> images')

	// Create FsTools instance
	mut fs_tools := fs_factory.fs_tools(fs_id)

	// Test basic find from root
	println('\nTesting basic find from root...')
	mut results := fs_tools.find('/', FindOptions{
		recursive: true
	})!

	// Should find all items
	assert results.len == 8
	println('✓ Found all 8 items in recursive search')

	// Check that we found the expected items
	mut found_items := map[string]FSItemType{}
	for result in results {
		found_items[result.path] = result.result_type
	}

	assert found_items['/'] == .directory
	assert found_items['/documents'] == .directory
	assert found_items['/images'] == .directory
	assert found_items['/documents/subdir'] == .directory
	assert found_items['/documents/document.txt'] == .file
	assert found_items['/images/image.png'] == .file
	assert found_items['/documents/subdir/subfile.txt'] == .file
	assert found_items['/doc_link.txt'] == .symlink
	assert found_items['/images_link'] == .symlink
	println('✓ All items found with correct paths and types')

	// Test non-recursive find from root
	println('\nTesting non-recursive find from root...')
	results = fs_tools.find('/', FindOptions{
		recursive: false
	})!

	// Should only find items directly in root
	assert results.len == 5
	println('✓ Found 5 items in non-recursive search')

	// Check that we found the expected items
	found_items = map[string]FSItemType{}
	for result in results {
		found_items[result.path] = result.result_type
	}

	assert found_items['/'] == .directory
	assert found_items['/documents'] == .directory
	assert found_items['/images'] == .directory
	assert '/documents/subdir' !in found_items
	println('✓ Non-recursive search only found direct children')

	// Test find with include patterns
	println('\nTesting find with include patterns...')
	results = fs_tools.find('/', FindOptions{
		recursive:        true
		include_patterns: ['*.txt']
	})!

	// Should find only .txt files
	assert results.len == 2
	println('✓ Found 2 .txt files with include pattern')

	found_items = map[string]FSItemType{}
	for result in results {
		found_items[result.path] = result.result_type
	}

	assert found_items['/documents/document.txt'] == .file
	assert found_items['/documents/subdir/subfile.txt'] == .file
	println('✓ Include pattern correctly filtered results')

	// Test find with exclude patterns
	println('\nTesting find with exclude patterns...')
	results = fs_tools.find('/', FindOptions{
		recursive:        true
		exclude_patterns: ['*.png']
	})!

	// Should find all items except the .png file
	assert results.len == 7
	println('✓ Found 7 items excluding .png files')

	found_items = map[string]FSItemType{}
	for result in results {
		found_items[result.path] = result.result_type
	}

	assert '/images/image.png' !in found_items
	assert found_items['/images'] == .directory
	println('✓ Exclude pattern correctly filtered results')

	// Test find with max_depth
	println('\nTesting find with max_depth...')
	results = fs_tools.find('/', FindOptions{
		recursive: true
		max_depth: 1
	})!

	// Should find root and its direct children only
	assert results.len == 6
	println('✓ Found 6 items with max_depth=1')

	found_items = map[string]FSItemType{}
	for result in results {
		found_items[result.path] = result.result_type
	}

	assert found_items['/'] == .directory
	assert found_items['/documents'] == .directory
	assert found_items['/images'] == .directory
	assert '/documents/subdir' !in found_items
	assert '/documents/subdir/subfile.txt' !in found_items
	println('✓ Max depth correctly limited search depth')

	// Test find from subdirectory
	println('\nTesting find from subdirectory...')
	results = fs_tools.find('/documents', FindOptions{
		recursive: true
	})!

	// Should find items in /documents and its subdirectories
	assert results.len == 4
	println('✓ Found 4 items in subdirectory search')

	found_items = map[string]FSItemType{}
	for result in results {
		found_items[result.path] = result.result_type
	}

	assert found_items['/documents'] == .directory
	assert found_items['/documents/document.txt'] == .file
	assert found_items['/documents/subdir'] == .directory
	assert found_items['/documents/subdir/subfile.txt'] == .file
	assert '/' !in found_items
	println('✓ Subdirectory search correctly rooted at /documents')

	println('\nFsTools find basic test completed successfully!')
}

fn test_symlink_find() {
	println('\nTesting FsTools find with symlinks...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create a new filesystem
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem_symlink_find'
		description: 'Filesystem for testing FsTools find with symlinks'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_id := fs_factory.fs.set(my_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       fs_id
		parent_id:   0 // Root has no parent
		description: 'Root directory for testing symlink find'
	)!

	// Save the root directory
	root_dir_id := fs_factory.fs_dir.set(root_dir)!

	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir_id
	my_fs.id = fs_id // Set the ID to ensure we update the existing object
	fs_factory.fs.set(my_fs)!

	// Retrieve the updated filesystem object
	my_fs = fs_factory.fs.get(fs_id)!

	// Create test directory
	mut dir1 := fs_factory.fs_dir.new(
		name:        'target_dir'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Target directory for symlink'
	)!
	dir1_id := fs_factory.fs_dir.set(dir1)!

	// Create test blob
	mut test_blob := fs_factory.fs_blob.new(
		data: 'Symlink test content'.bytes()
	)!
	blob_id := fs_factory.fs_blob.set(test_blob)!

	// Create test file
	mut file1 := fs_factory.fs_file.new(
		name:        'target_file.txt'
		fs_id:       fs_id
		directories: [dir1_id]
		blobs:       [blob_id]
		description: 'Target file for symlink'
		mime_type:   .txt
	)!
	file1_id := fs_factory.fs_file.set(file1)!

	// Update dir1 with file1
	dir1.files = [file1_id]
	dir1.id = dir1_id // Set the ID to ensure we update the existing object
	fs_factory.fs_dir.set(dir1)!

	// Create symlinks
	mut symlink1 := fs_factory.fs_symlink.new(
		name:        'file_link.txt'
		fs_id:       fs_id
		parent_id:   root_dir_id
		target_id:   file1_id
		target_type: .file
		description: 'Symlink to target_file.txt'
	)!
	symlink1_id := fs_factory.fs_symlink.set(symlink1)!

	mut symlink2 := fs_factory.fs_symlink.new(
		name:        'dir_link'
		fs_id:       fs_id
		parent_id:   root_dir_id
		target_id:   dir1_id
		target_type: .directory
		description: 'Symlink to target_dir'
	)!
	symlink2_id := fs_factory.fs_symlink.set(symlink2)!

	// Update root_dir with dir1 and symlinks
	root_dir.directories = [dir1_id]
	root_dir.symlinks = [symlink1_id, symlink2_id]
	root_dir.id = root_dir_id // Set the ID to ensure we update the existing object
	fs_factory.fs_dir.set(root_dir)!

	// Create FsTools instance
	mut fs_tools := fs_factory.fs_tools(fs_id)

	// Test find without following symlinks
	println('Testing find without following symlinks...')
	mut results := fs_tools.find('/', FindOptions{
		recursive:       true
		follow_symlinks: false
	})!

	// Should find root, target_dir, symlinks, and target_file.txt
	assert results.len == 5
	println('✓ Found 5 items without following symlinks')

	mut found_items := map[string]FSItemType{}
	for result in results {
		found_items[result.path] = result.result_type
	}

	assert found_items['/'] == .directory
	assert found_items['/target_dir'] == .directory
	assert found_items['/file_link.txt'] == .symlink
	assert found_items['/dir_link'] == .symlink
	assert found_items['/target_dir/target_file.txt'] == .file
	println('✓ Symlinks found as symlinks when follow_symlinks=false')

	// Test find with following symlinks
	println('Testing find with following symlinks...')
	results = fs_tools.find('/', FindOptions{
		recursive:       true
		follow_symlinks: true
	})!

	// Should find root, target_dir, and target_file.txt (but not the symlinks themselves)
	assert results.len == 3
	println('✓ Found 3 items when following symlinks')

	found_items = map[string]FSItemType{}
	for result in results {
		found_items[result.path] = result.result_type
	}

	assert found_items['/'] == .directory
	assert found_items['/target_dir'] == .directory
	assert found_items['/target_dir/target_file.txt'] == .file
	assert '/file_link.txt' !in found_items
	assert '/dir_link' !in found_items
	println('✓ Symlinks followed correctly when follow_symlinks=true')

	println('FsTools find symlink test completed successfully!')
}

fn test_find_edge_cases() {
	println('\nTesting FsTools find edge cases...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create a new filesystem
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem_find_edge'
		description: 'Filesystem for testing FsTools find edge cases'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_id := fs_factory.fs.set(my_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       fs_id
		parent_id:   0 // Root has no parent
		description: 'Root directory for testing find edge cases'
	)!

	// Save the root directory
	root_dir_id := fs_factory.fs_dir.set(root_dir)!

	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir_id
	fs_factory.fs.set(my_fs)!

	// Create FsTools instance
	mut fs_tools := fs_factory.fs_tools(fs_id)

	// Test find with non-existent path
	println('Testing find with non-existent path...')
	mut result := fs_tools.find('/nonexistent', FindOptions{}) or {
		println('✓ Find correctly failed with non-existent path')
		return
	}

	// If we get here, the error handling didn't work as expected
	panic('Find should have failed with non-existent path')

	println('FsTools find edge cases test completed successfully!')
}
