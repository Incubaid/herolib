module herofs

import freeflowuniverse.herolib.hero.herofs

// Test that files are automatically added to directories when created
fn test_file_creation_adds_to_directory() ! {
	mut factory := herofs.new()!

	// Create filesystem
	mut fs := factory.fs.new(name: 'test_fs', quota_bytes: 1000000)!
	fs = factory.fs.set(fs)!

	// Create directory
	mut dir := factory.fs_dir.new(name: 'test_dir', fs_id: fs.id)!
	dir = factory.fs_dir.set(dir)!

	// Create blob
	mut blob := factory.fs_blob.new(data: [u8(1), 2, 3])!
	blob = factory.fs_blob.set(blob)!

	// Create file with directory association
	mut file := factory.fs_file.new(
		name:        'test_file.txt'
		fs_id:       fs.id
		directories: [dir.id]
		blobs:       [blob.id]
		mime_type:   .txt
	)!
	file = factory.fs_file.set(file)!

	// Verify file was added to directory's files array
	updated_dir := factory.fs_dir.get(dir.id)!
	assert file.id in updated_dir.files, 'File should be in directory files array'
	assert updated_dir.files.len == 1, 'Directory should have exactly 1 file'

	// Verify list_by_directory returns the file
	files_in_dir := factory.fs_file.list_by_directory(dir.id)!
	assert files_in_dir.len == 1, 'list_by_directory should return 1 file'
	assert files_in_dir[0].id == file.id, 'Returned file should match created file'
}
