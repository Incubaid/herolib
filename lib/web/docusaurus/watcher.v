module docusaurus

// not longer working because is coming from doctree

// import freeflowuniverse.herolib.osal.notifier
// import os

// fn watch_docs(docs_path string, path_src string, path_build string) ! {
// 	mut n := notifier.new('docsite_watcher') or {
// 		eprintln('Failed to create watcher: ${err}')
// 		return
// 	}

// 	n.args['path_src'] = path_src
// 	n.args['path_build'] = path_build

// 	// Add watch with captured args
// 	n.add_watch(docs_path, fn (event notifier.NotifyEvent, path string, args map[string]string) {
// 		handle_file_change(event, path, args) or { eprintln('Error handling file change: ${err}') }
// 	})!

// 	n.start()!
// }

// // handle_file_change processes file system events
// fn handle_file_change(event notifier.NotifyEvent, path string, args map[string]string) ! {
// 	file_base := os.base(path)
// 	is_dir := os.is_dir(path)

// 	// Skip files starting with #
// 	if file_base.starts_with('#') {
// 		return
// 	}

// 	// For files (not directories), check extensions
// 	if !is_dir {
// 		ext := os.file_ext(path).to_lower()
// 		if ext !in ['.md', '.png', '.jpeg', '.jpg'] {
// 			return
// 		}
// 	}

// 	// Get relative path from docs directory
// 	rel_path := path.replace('${args['path_src']}/docs/', '')
// 	dest_path := '${args['path_build']}/docs/${rel_path}'

// 	match event {
// 		.create, .modify {
// 			if is_dir {
// 				// For directories, just ensure they exist
// 				os.mkdir_all(dest_path) or {
// 					return error('Failed to create directory ${dest_path}: ${err}')
// 				}
// 				println('Created directory: ${rel_path}')
// 			} else {
// 				// For files, ensure parent directory exists and copy
// 				os.mkdir_all(os.dir(dest_path)) or {
// 					return error('Failed to create directory ${os.dir(dest_path)}: ${err}')
// 				}
// 				os.cp(path, dest_path) or {
// 					return error('Failed to copy ${path} to ${dest_path}: ${err}')
// 				}
// 				println('Updated: ${rel_path}')
// 			}
// 		}
// 		.delete {
// 			if os.exists(dest_path) {
// 				if is_dir {
// 					os.rmdir_all(dest_path) or {
// 						return error('Failed to delete directory ${dest_path}: ${err}')
// 					}
// 					println('Deleted directory: ${rel_path}')
// 				} else {
// 					os.rm(dest_path) or { return error('Failed to delete ${dest_path}: ${err}') }
// 					println('Deleted: ${rel_path}')
// 				}
// 			}
// 		}
// 		.rename {
// 			// For rename events, fswatch provides the new path in the event
// 			// The old path is already removed, so we just need to handle the new path
// 			if is_dir {
// 				os.mkdir_all(dest_path) or {
// 					return error('Failed to create directory ${dest_path}: ${err}')
// 				}
// 				println('Renamed directory to: ${rel_path}')
// 			} else {
// 				os.mkdir_all(os.dir(dest_path)) or {
// 					return error('Failed to create directory ${os.dir(dest_path)}: ${err}')
// 				}
// 				os.cp(path, dest_path) or {
// 					return error('Failed to copy ${path} to ${dest_path}: ${err}')
// 				}
// 				println('Renamed to: ${rel_path}')
// 			}
// 		}
// 	}
// }

// pub fn (mut s DocSite) dev_watch(args DevArgs) ! {
// 	s.generate()!

// 	// Create screen session for docusaurus development server
// 	mut screen_name := 'docusaurus'
// 	mut sf := screen.new()!

// 	// Add and start a new screen session
// 	mut scr := sf.add(
// 		name:   screen_name
// 		cmd:    '/bin/bash'
// 		start:  true
// 		attach: false
// 		reset:  true
// 	)!

// 	// Send commands to the screen session
// 	console.print_item('To view the server output:: cd ${s.path_build.path}')
// 	scr.cmd_send('cd ${s.path_build.path}')!

// 	// Start script recording in the screen session for log streaming
// 	log_file := '/tmp/docusaurus_${screen_name}.log'
// 	script_cmd := 'script -f ${log_file}'
// 	scr.cmd_send(script_cmd)!

// 	// Small delay to ensure script is ready
// 	time.sleep(500 * time.millisecond)

// 	// Start bun in the scripted session
// 	bun_cmd := 'bun start -p ${args.port} -h ${args.host}'
// 	scr.cmd_send(bun_cmd)!

// 	// Stream the log output to current terminal
// 	console.print_header(' Docusaurus Development Server')
// 	console.print_item('Streaming server output... Press Ctrl+C to detach and leave server running')
// 	console.print_item('Server will be available at: http://${args.host}:${args.port}')
// 	console.print_item('To reattach later: screen -r ${screen_name}')
// 	println('')

// 	// Stream logs until user interrupts
// 	s.stream_logs(log_file, screen_name)!

// 	// After user interrupts, show final instructions
// 	console.print_header(' Server Running in Background')
// 	console.print_item('✓ Development server is running in background')
// 	console.print_item('Server URL: http://${args.host}:${args.port}')
// 	console.print_item('To reattach: screen -r ${screen_name}')
// 	console.print_item('To stop server: screen -S ${screen_name} -X kill')
// 	// console.print_item('The site content is on: ${s.path_src.path}/docs')

// 	// Start the watcher in a separate thread
// 	// mut tf:=spawn watch_docs(docs_path, s.path_src.path, s.path_build.path)
// 	// tf.wait()!
// 	println('\n')

// 	if args.open {
// 		s.open()!
// 	}

// }

// // Stream logs from script file to current terminal until user interrupts
// fn (mut s DocSite) stream_logs(log_file string, screen_name string) ! {
// 	// Wait a moment for the log file to be created
// 	mut attempts := 0
// 	for !os.exists(log_file) && attempts < 10 {
// 		time.sleep(200 * time.millisecond)
// 		attempts++
// 	}

// 	if !os.exists(log_file) {
// 		console.print_stderr('Warning: Log file not created, falling back to screen attach')
// 		console.print_item('Attaching to screen session... Press Ctrl+A then D to detach')
// 		// Fallback to direct screen attach
// 		osal.execute_interactive('screen -r ${screen_name}')!
// 		return
// 	}

// 	// Use tail -f to stream the log file
// 	// The -f flag follows the file as it grows
// 	tail_cmd := 'tail -f ${log_file}'

// 	// Execute tail in interactive mode - this will stream until Ctrl+C
// 	osal.execute_interactive(tail_cmd) or {
// 		// If tail fails, try alternative approach
// 		console.print_stderr('Log streaming failed, attaching to screen session...')
// 		osal.execute_interactive('screen -r ${screen_name}')!
// 		return
// 	}

// 	// Clean up the log file after streaming
// 	os.rm(log_file) or {}
// }
