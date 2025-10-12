#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.osal.notifier
import os
import time

fn on_file_change(event notifier.NotifyEvent, path string, args map[string]string) {
	match event {
		.create { println('File created: ${path}') }
		.modify { println('File modified: ${path}') }
		.delete { println('File deleted: ${path}') }
		.rename { println('File renamed: ${path}') }
	}
}

fn main() {
	// Create test directory and files
	test_dir := '/tmp/notifytest'
	if !os.exists(test_dir) {
		os.mkdir_all(test_dir)!
		os.write_file('${test_dir}/test.txt', 'initial content')!
		os.mkdir('${test_dir}/subdir')!
		os.write_file('${test_dir}/subdir/test2.txt', 'test content')!
	}

	// Create a new notifier
	mut n := notifier.new('test_watcher')!

	// Add files to watch
	n.add_watch('${test_dir}', on_file_change)!

	// Start watching
	n.start()!

	println('Watching files in ${test_dir} for 60 seconds...')
	println('Try these operations to test the notifier:')
	println('1. Modify a file: echo "new content" > ${test_dir}/test.txt')
	println('2. Create a file: touch ${test_dir}/newfile.txt')
	println('3. Delete a file: rm ${test_dir}/test.txt')
	println('4. Rename a file: mv ${test_dir}/test.txt ${test_dir}/renamed.txt')

	// Keep the program running for 60 seconds
	time.sleep(60 * time.second)

	// Clean up
	n.stop()
	println('\nWatch period ended.')
}
