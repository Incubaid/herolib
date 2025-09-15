module herofs

import freeflowuniverse.herolib.hero.db

fn test_basic() {
	println('Testing FsDir functionality...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!
	println('HeroFS factory initialized')

	// Create a new filesystem (required for FsDir)
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem'
		description: 'Filesystem for testing FsDir functionality'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_factory.fs.set(mut my_fs)!
	println('Created test filesystem with ID: ${my_fs.id}')

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       my_fs.id
		parent_id:   0 // Root has no parent
		description: 'Root directory for testing'
	)!

	// Save the root directory
	fs_factory.fs_dir.set(mut root_dir)!
	root_dir_id := root_dir.id
	println('Created root directory with ID: ${root_dir_id}')

	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir_id
	fs_factory.fs.set(mut my_fs)!

	// Create test directories with various parameters
	mut test_dir1 := fs_factory.fs_dir.new(
		name:        'test_dir1'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'First test directory'
	)!

	mut test_dir2 := fs_factory.fs_dir.new(
		name:        'test_dir2'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Second test directory with tags'
		tags:        ['test', 'directory', 'example']
	)!

	mut test_dir3 := fs_factory.fs_dir.new(
		name:        'test_dir3'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Third test directory with comments'
		comments:    [
			db.CommentArg{
				comment: 'This is a test comment'
				author:  1
			},
		]
	)!

	// Save the test directories
	fs_factory.fs_dir.set(mut test_dir1)!
	fs_factory.fs_dir.set(mut test_dir2)!
	fs_factory.fs_dir.set(mut test_dir3)!

	println('Created test directories:')
	println('- ${test_dir1.name} with ID: ${dir1.id}')
	println('- ${test_dir2.name} with ID: ${dir2.id}')
	println('- ${test_dir3.name} with ID: ${dir3.id}')

	// Test loading directories by ID
	println('\nTesting directory loading...')

	loaded_root_dir := fs_factory.fs_dir.get(root_dir_id)!
	assert loaded_root_dir.name == root_dir.name
	assert loaded_root_dir.description == root_dir.description
	assert loaded_root_dir.fs_id == root_dir.fs_id
	assert loaded_root_dir.parent_id == root_dir.parent_id
	println('✓ Loaded root directory: ${loaded_root_dir.name} (ID: ${loaded_root_dir.id})')

	loaded_dir1 := fs_factory.fs_dir.get(dir1_id)!
	assert loaded_dir1.name == test_dir1.name
	assert loaded_dir1.description == test_dir1.description
	assert loaded_dir1.fs_id == test_dir1.fs_id
	assert loaded_dir1.parent_id == test_dir1.parent_id
	println('✓ Loaded test_dir1: ${loaded_dir1.name} (ID: ${loaded_dir1.id})')

	loaded_dir2 := fs_factory.fs_dir.get(dir2_id)!
	assert loaded_dir2.name == test_dir2.name
	assert loaded_dir2.description == test_dir2.description
	assert loaded_dir2.fs_id == test_dir2.fs_id
	assert loaded_dir2.parent_id == test_dir2.parent_id
	assert loaded_dir2.tags == test_dir2.tags
	println('✓ Loaded test_dir2: ${loaded_dir2.name} (ID: ${loaded_dir2.id})')

	loaded_dir3 := fs_factory.fs_dir.get(dir3_id)!
	assert loaded_dir3.name == test_dir3.name
	assert loaded_dir3.description == test_dir3.description
	assert loaded_dir3.fs_id == test_dir3.fs_id
	assert loaded_dir3.parent_id == test_dir3.parent_id
	println('✓ Loaded test_dir3: ${loaded_dir3.name} (ID: ${loaded_dir3.id})')

	// Verify that loaded directories match the original ones
	println('\nVerifying data integrity...')
	println('✓ All directory data integrity checks passed')

	// Test exist method
	println('\nTesting directory existence checks...')

	mut exists := fs_factory.fs_dir.exist(root_dir_id)!
	assert exists == true
	println('✓ Root directory exists: ${exists}')

	exists = fs_factory.fs_dir.exist(dir1_id)!
	assert exists == true
	println('✓ Test directory 1 exists: ${exists}')

	exists = fs_factory.fs_dir.exist(dir2_id)!
	assert exists == true
	println('✓ Test directory 2 exists: ${exists}')

	exists = fs_factory.fs_dir.exist(dir3_id)!
	assert exists == true
	println('✓ Test directory 3 exists: ${exists}')

	// Test with non-existent ID
	exists = fs_factory.fs_dir.exist(999999)!
	assert exists == false
	println('✓ Non-existent directory exists: ${exists}')

	println('\nFsDir basic test completed successfully!')
}

fn test_directory_operations() {
	println('\nTesting FsDir operations...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create a new filesystem (required for FsDir)
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem_ops'
		description: 'Filesystem for testing FsDir operations'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_factory.fs.set(mut my_fs)!

	// Create a test directory
	test_dir := fs_factory.fs_dir.new(
		name:        'test_operations'
		fs_id:       my_fs.id
		parent_id:   0
		description: 'Directory for testing operations'
	)!

	// Save the test directory
	fs_factory.fs_dir.set(mut test_dir)!

	// Test adding items to directory
	println('Testing adding items to directory...')

	
	test_dir.directories << root_dir_id
	fs_factory.fs_dir.set(mut test_dir)!
	fs_factory.fs_dir.get(test_dir.id)!
	assert updated_dir_id == updated_test_dir.id
	println('✓ Added directory to directories list')

	// Add a file
	test_dir.files << 123
	fs_factory.fs_dir.set(mut test_dir)!
	updatedir:=fs_factory.fs_dir.get(mut test_dir.id)!
	assert updatedir.id == test_dir.id
	println('✓ Added file to files list')

	// Add a symlink
	test_dir.symlinks << 456
	fs_factory.fs_dir.set(mut test_dir)!
	updated_test_dir = fs_factory.fs_dir.get(test_dir.id)!
	assert updated_test_dir.id == test_dir.id
	println('✓ Added symlink to symlinks list')

	// Verify the items were added
	loaded_dir := fs_factory.fs_dir.get(dir_id)!
	assert loaded_dir.directories.len == 1
	assert loaded_dir.directories[0] == root_dir_id
	assert loaded_dir.files.len == 1
	assert loaded_dir.files[0] == 123
	assert loaded_dir.symlinks.len == 1
	assert loaded_dir.symlinks[0] == 456
	println('✓ Verified all items were added to directory')

	println('FsDir operations test completed successfully!')
}

fn test_directory_deletion() {
	println('\nTesting FsDir deletion...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create a new filesystem (required for FsDir)
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem_delete'
		description: 'Filesystem for testing FsDir deletion'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_id := fs_factory.fs.set(my_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       fs_id
		parent_id:   0 // Root has no parent
		description: 'Root directory for testing deletion'
	)!

	// Save the root directory
	root_dir_id := fs_factory.fs_dir.set(root_dir)!

	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir_id
	fs_factory.fs.set(my_fs)!

	// Create a test directory
	mut test_dir := fs_factory.fs_dir.new(
		name:        'test_delete'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Directory for testing deletion'
	)!

	// Save the test directory
	dir_id := fs_factory.fs_dir.set(test_dir)!

	// Verify directory exists
	mut exists := fs_factory.fs_dir.exist(dir_id)!
	assert exists == true
	println('✓ Directory exists before deletion')

	// Delete the directory
	fs_factory.fs_dir.delete(dir_id)!

	// Verify directory no longer exists
	exists = fs_factory.fs_dir.exist(dir_id)!
	assert exists == false
	println('✓ Directory no longer exists after deletion')

	// Verify directory was removed from parent's directories list
	loaded_root := fs_factory.fs_dir.get(root_dir_id)!
	mut found := false
	for dir in loaded_root.directories {
		if dir == dir_id {
			found = true
			break
		}
	}
	assert found == false
	println("✓ Directory removed from parent's directories list")

	println('FsDir deletion test completed successfully!')
}
