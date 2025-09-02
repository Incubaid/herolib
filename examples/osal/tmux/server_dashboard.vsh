#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.osal.tmux
import freeflowuniverse.herolib.osal.core as osal
import time
import os

// Configuration
const session_name = 'server_dashboard'
const window_name = 'dashboard'
const python_port = 8000
const ttyd_port = 7890

// Command line argument handling
fn show_help() {
	println('=== Tmux Server Dashboard ===')
	println('Usage:')
	println('  ${os.args[0]}              # Start the dashboard')
	println('  ${os.args[0]} -editable    # Start dashboard with editable ttyd')
	println('  ${os.args[0]} -down        # Stop dashboard and cleanup')
	println('  ${os.args[0]} -status      # Show dashboard status')
	println('  ${os.args[0]} -restart     # Restart the dashboard')
	println('  ${os.args[0]} -help        # Show this help')
	println('')
	println('Dashboard includes:')
	println('  • Python HTTP Server (port ${python_port})')
	println('  • Counter service (updates every 5 seconds)')
	println('  • Hero Web (compile and run hero web server)')
	println('  • CPU Monitor (htop)')
	println('  • Web access via ttyd (port ${ttyd_port})')
	println('')
	println('ttyd modes:')
	println('  • Default: read-only access to terminal')
	println('  • -editable: allows writing/editing in the terminal')
}

fn stop_dashboard() ! {
	println('=== Stopping Dashboard ===')

	// Kill ttyd processes
	println('Stopping ttyd processes...')
	os.execute('pkill ttyd')

	// Kill tmux session
	println('Stopping tmux session...')
	mut t := tmux.new()!
	if t.session_exist(session_name) {
		mut session := t.session_get(session_name)!
		session.stop()!
		println('✓ Tmux session "${session_name}" stopped')
	} else {
		println('• Session "${session_name}" not found')
	}

	// Check for any remaining processes on our ports
	println('Checking for processes on ports...')

	// Check Python server port
	python_check := os.execute('lsof -i :${python_port}')
	if python_check.exit_code == 0 {
		println('• Found processes on port ${python_port}')
		println(python_check.output)
	} else {
		println('✓ Port ${python_port} is free')
	}

	// Check ttyd port
	ttyd_check := os.execute('lsof -i :${ttyd_port}')
	if ttyd_check.exit_code == 0 {
		println('• Found processes on port ${ttyd_port}')
		println(ttyd_check.output)
	} else {
		println('✓ Port ${ttyd_port} is free')
	}

	println('=== Dashboard stopped ===')
}

fn show_status() ! {
	println('=== Dashboard Status ===')

	mut t := tmux.new()!

	// Check tmux session
	if t.session_exist(session_name) {
		println('✓ Tmux session "${session_name}" is running')

		mut session := t.session_get(session_name)!
		mut window := session.window_get(name: window_name) or {
			println('✗ Window "${window_name}" not found')
			return
		}
		println('✓ Window "${window_name}" exists with ${window.panes.len} panes')

		// Show pane details
		for i, pane in window.panes {
			service_name := match i {
				0 { 'Python HTTP Server' }
				1 { 'Counter Service' }
				2 { 'Hero Web Service' }
				3 { 'CPU Monitor' }
				else { 'Service ${i + 1}' }
			}

			mut pane_mut := pane
			stats := pane_mut.stats() or {
				println('  Pane ${i + 1} (${service_name}): ID=%${pane.id}, PID=${pane.pid} (stats unavailable)')
				continue
			}

			memory_mb := f64(stats.memory_bytes) / (1024.0 * 1024.0)
			println('  Pane ${i + 1} (${service_name}): ID=%${pane.id}, CPU=${stats.cpu_percent:.1f}%, Memory=${memory_mb:.1f}MB')
		}
	} else {
		println('✗ Tmux session "${session_name}" not running')
	}

	// Check ports
	python_check := os.execute('lsof -i :${python_port}')
	if python_check.exit_code == 0 {
		println('✓ Python server running on port ${python_port}')
	} else {
		println('✗ No process on port ${python_port}')
	}

	ttyd_check := os.execute('lsof -i :${ttyd_port}')
	if ttyd_check.exit_code == 0 {
		println('✓ ttyd running on port ${ttyd_port}')
	} else {
		println('✗ No process on port ${ttyd_port}')
	}

	println('')
	println('Access URLs:')
	println('  • Python Server: http://localhost:${python_port}')
	println('  • Web Terminal: http://localhost:${ttyd_port}')
	println('  • Tmux attach: tmux attach-session -t ${session_name}')
}

fn restart_dashboard() ! {
	println('=== Restarting Dashboard ===')
	stop_dashboard()!
	time.sleep(2000 * time.millisecond) // Wait 2 seconds
	start_dashboard()!
}

fn start_dashboard_with_mode(ttyd_editable bool) ! {
	println('=== Server Dashboard with 4 Panes ===')
	println('Setting up tmux session with:')
	println('  1. Python HTTP Server (port ${python_port})')
	println('  2. Counter Service (updates every 5 seconds)')
	println('  3. Hero Web (compile and run hero web server)')
	println('  4. CPU Monitor (htop)')
	println('')

	// Initialize tmux
	mut t := tmux.new()!

	if !t.is_running()! {
		println('Starting tmux server...')
		t.start()!
	}

	// Clean up existing session if it exists
	if t.session_exist(session_name) {
		println('Cleaning up existing ${session_name} session...')
		t.session_delete(session_name)!
	}

	// Create new session
	println('Creating ${session_name} session...')
	mut session := t.session_create(name: session_name)!

	// Create main window with initial bash shell
	println('Creating dashboard window...')
	mut window := session.window_new(name: window_name, cmd: 'bash', reset: true)!

	// Wait for initial setup
	time.sleep(500 * time.millisecond)
	t.scan()!

	println('\n=== Setting up 4-pane layout ===')

	// Get the main window
	window = session.window_get(name: window_name)!

	// Split horizontally first (left and right halves)
	println('1. Splitting horizontally for left/right layout...')
	mut right_pane := window.pane_split_horizontal('bash')!
	time.sleep(300 * time.millisecond)
	window.scan()!

	// Split left pane vertically (top-left and bottom-left)
	println('2. Splitting left pane vertically...')
	window.scan()!
	if window.panes.len >= 2 {
		mut left_pane := window.panes[0] // First pane should be the left one
		left_pane.select()!
		time.sleep(200 * time.millisecond)
		mut bottom_left_pane := window.pane_split_vertical('bash')!
		time.sleep(300 * time.millisecond)
		window.scan()!
	}

	// Split right pane vertically (top-right and bottom-right)
	println('3. Splitting right pane vertically...')
	window.scan()!
	if window.panes.len >= 3 {
		// Find the rightmost pane (should be the last one after horizontal split)
		mut right_pane_current := window.panes[window.panes.len - 1]
		right_pane_current.select()!
		time.sleep(200 * time.millisecond)
		mut bottom_right_pane := window.pane_split_vertical('bash')!
		time.sleep(300 * time.millisecond)
		window.scan()!
	}

	// Set a proper 2x2 tiled layout using tmux command
	println('4. Setting 2x2 tiled layout...')
	os.execute('tmux select-layout -t ${session_name}:${window_name} tiled')
	time.sleep(500 * time.millisecond)
	window.scan()!

	println('5. Layout complete! We now have 4 panes in 2x2 grid.')

	// Refresh to get all panes
	window.scan()!
	println('\nCurrent panes: ${window.panes.len}')
	for i, pane in window.panes {
		println('  Pane ${i}: ID=%${pane.id}, PID=${pane.pid}')
	}

	if window.panes.len < 4 {
		eprintln('Expected 4 panes, but got ${window.panes.len}')
		exit(1)
	}

	println('\n=== Starting services in each pane ===')

	// Pane 1 (top-left): Python HTTP Server
	println('Starting Python HTTP Server in pane 1...')
	mut pane1 := window.panes[0]
	pane1.select()!
	pane1.send_command('echo "=== Python HTTP Server Port 8000 ==="')!
	pane1.send_command('cd /tmp && python3 -m http.server ${python_port}')!

	time.sleep(500 * time.millisecond)

	// Pane 2 (bottom-left): Counter Service
	println('Starting Counter Service in pane 2...')
	mut pane2 := window.panes[1]
	pane2.select()!
	pane2.send_command('echo "=== Counter Service - Updates every 5 seconds ==="')!
	pane2.send_command('while true; do echo "Count: $(date)"; sleep 5; done')!

	time.sleep(500 * time.millisecond)

	// Pane 3 (top-right): Hero Web
	println('Starting Hero Web in pane 3...')
	mut pane3 := window.panes[2]
	pane3.select()!
	pane3.send_command('echo "=== Hero Web Server ==="')!
	pane3.send_command('hero web')!

	time.sleep(500 * time.millisecond)

	// Pane 4 (bottom-right): CPU Monitor
	println('Starting CPU Monitor in pane 4...')
	mut pane4 := window.panes[3]
	pane4.select()!
	pane4.send_command('echo "=== CPU Monitor ==="')!
	pane4.send_command('htop')!

	println('\n=== All services started! ===')

	// Wait a moment for services to initialize
	time.sleep(2000 * time.millisecond)

	// Refresh and show current state
	t.scan()!
	window = session.window_get(name: window_name)!

	println('\n=== Current Dashboard State ===')
	for i, mut pane in window.panes {
		stats := pane.stats() or {
			println('  Pane ${i + 1}: ID=%${pane.id}, PID=${pane.pid} (stats unavailable)')
			continue
		}
		memory_mb := f64(stats.memory_bytes) / (1024.0 * 1024.0)
		service_name := match i {
			0 { 'Python Server' }
			1 { 'Counter Service' }
			2 { 'Hero Web' }
			3 { 'CPU Monitor' }
			else { 'Unknown' }
		}
		println('  Pane ${i + 1} (${service_name}): ID=%${pane.id}, CPU=${stats.cpu_percent:.1f}%, Memory=${memory_mb:.1f}MB')
	}

	println('\n=== Access Information ===')
	println('• Python HTTP Server: http://localhost:${python_port}')
	println('• Tmux Session: tmux attach-session -t ${session_name}')
	println('')
	println('=== Pane Resize Commands ===')
	println('To resize panes, attach to the session and use:')
	println('  Ctrl+B then Arrow Keys (hold Ctrl+B and press arrow keys)')
	println('  Or programmatically:')
	for i, pane in window.panes {
		service_name := match i {
			0 { 'Python Server' }
			1 { 'Counter Service' }
			2 { 'Hero Web' }
			3 { 'CPU Monitor' }
			else { 'Unknown' }
		}
		println('  # Resize ${service_name} pane:')
		println('  tmux resize-pane -t ${session_name}:${window_name}.%${pane.id} -U 5  # Up')
		println('  tmux resize-pane -t ${session_name}:${window_name}.%${pane.id} -D 5  # Down')
		println('  tmux resize-pane -t ${session_name}:${window_name}.%${pane.id} -L 5  # Left')
		println('  tmux resize-pane -t ${session_name}:${window_name}.%${pane.id} -R 5  # Right')
	}

	println('\n=== Dashboard is running! ===')
	println('Attach to view: tmux attach-session -t ${session_name}')
	println('Press Ctrl+B then d to detach from session')
	println('To stop all services: tmux kill-session -t ${session_name}')
	println('Running the browser-based dashboard: TTYD')

	mode_str := if ttyd_editable { 'editable' } else { 'read-only' }
	println('Starting ttyd in ${mode_str} mode...')

	window.run_ttyd(port: ttyd_port, editable: ttyd_editable) or {
		println('Failed to start ttyd: ${err}')
	}
}

fn start_dashboard() ! {
	start_dashboard_with_mode(false)!
}

fn main() {
	mut ttyd_editable := false // Local flag for ttyd editable mode

	// Main execution with argument handling
	if os.args.len > 1 {
		command := os.args[1]
		match command {
			'-editable' {
				ttyd_editable = true
				start_dashboard_with_mode(ttyd_editable) or {
					eprintln('Error starting dashboard: ${err}')
					exit(1)
				}
			}
			'-down' {
				stop_dashboard() or {
					eprintln('Error stopping dashboard: ${err}')
					exit(1)
				}
			}
			'-status' {
				show_status() or {
					eprintln('Error getting status: ${err}')
					exit(1)
				}
			}
			'-restart' {
				restart_dashboard() or {
					eprintln('Error restarting dashboard: ${err}')
					exit(1)
				}
			}
			'-help', '--help', '-h' {
				show_help()
			}
			else {
				eprintln('Unknown command: ${command}')
				show_help()
				exit(1)
			}
		}
	} else {
		// No arguments - start the dashboard
		start_dashboard_with_mode(ttyd_editable) or {
			eprintln('Error starting dashboard: ${err}')
			exit(1)
		}
	}
}
