module rcloneclient

fn test_rclone_new() {
	rclone := new('test_remote') or { panic(err) }
	assert rclone.name == 'test_remote'
}

fn test_check_installed() {
	installed := check_installed()
	// This test will pass or fail depending on whether rclone is installed
	// on the system. It's mainly for documentation purposes.
	println('RCloneClient installed: ${installed}')
}

// Note: The following tests are commented out as they require an actual rclone
// configuration and remote to work with. They serve as examples of how to use
// the RCloneClient module.

/*
fn test_rclone_operations() ! {
	mut rclone := new('my_remote')!
	
	// Test upload
	rclone.upload('./testdata', 'backup/testdata')!
	
	// Test download
	rclone.download('backup/testdata', './testdata_download')!
	
	// Test mount
	rclone.mount('backup', './mounted_backup')!
	
	// Test list
	content := rclone.list('backup')!
	println(content)
	
	// Test unmount
	rclone.unmount('./mounted_backup')!
}
*/
