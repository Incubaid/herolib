module logger

import os
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.core.pathlib

fn testsuite_begin() {
	if os.exists('/tmp/testlogs') {
		os.rmdir_all('/tmp/testlogs')!
	}
}

fn test_logger() {
	mut logger := new(LoggerFactoryArgs{
		path: '/tmp/testlogs'
	})!

	// Test stdout logging
	logger.log(LogItemArgs{
		cat:       'test-app'
		log:       'This is a test message\nWith a second line\nAnd a third line'
		logtype:   .stdout
		timestamp: ourtime.new('2022-12-05 20:14:35')!
	})!

	// Test error logging
	logger.log(LogItemArgs{
		cat:       'error-test'
		log:       'This is an error\nWith details'
		logtype:   .error
		timestamp: ourtime.new('2022-12-05 20:14:35')!
	})!

	logger.log(LogItemArgs{
		cat:       'test-app'
		log:       'This is a test message\nWith a second line\nAnd a third line'
		logtype:   .stdout
		timestamp: ourtime.new('2022-12-05 20:14:36')!
	})!

	logger.log(LogItemArgs{
		cat:       'error-test'
		log:       '
				This is an error
				
				With details
			'
		logtype:   .error
		timestamp: ourtime.new('2022-12-05 20:14:36')!
	})!

	logger.log(LogItemArgs{
		cat:       'error-test'
		log:       '
				aaa

				bbb
			'
		logtype:   .error
		timestamp: ourtime.new('2022-12-05 22:14:36')!
	})!

	logger.log(LogItemArgs{
		cat:       'error-test'
		log:       '
				aaa2

				bbb2
			'
		logtype:   .error
		timestamp: ourtime.new('2022-12-05 22:14:36')!
	})!

	// Verify log directory exists
	assert os.exists('/tmp/testlogs'), 'Log directory should exist'

	// Get log file
	files := os.ls('/tmp/testlogs')!
	assert files.len == 2

	mut file := pathlib.get_file(
		path:   '/tmp/testlogs/${files[0]}'
		create: false
	)!

	content := file.read()!.trim_space()

	items_stdout := logger.search(
		timestamp_from: ourtime.new('2022-11-1 20:14:35')!
		timestamp_to:   ourtime.new('2025-11-1 20:14:35')!
		logtype:        .stdout
	)!
	assert items_stdout.len == 2

	items_error := logger.search(
		timestamp_from: ourtime.new('2022-11-1 20:14:35')!
		timestamp_to:   ourtime.new('2025-11-1 20:14:35')!
		logtype:        .error
	)!
	assert items_error.len == 4
}

fn testsuite_end() {
	// if os.exists('/tmp/testlogs') {
	// 	os.rmdir_all('/tmp/testlogs')!
	// }
}
