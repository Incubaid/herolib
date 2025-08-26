module playcmds

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console

pub fn play_osal_core(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'osal.') {
		return
	}

	// Process done actions
	play_done(mut plbook)!
	
	// Process environment actions
	play_env(mut plbook)!
	
	// Process execution actions
	play_exec(mut plbook)!
	
	// Process package actions
	play_package(mut plbook)!
}

fn play_done(mut plbook PlayBook) ! {
	// done_set actions
	mut done_set_actions := plbook.find(filter: 'osal.done_set')!
	for mut action in done_set_actions {
		mut p := action.params
		key := p.get('key')!
		val := p.get('val')!
		
		console.print_header('Setting done flag: ${key} = ${val}')
		osal.done_set(key, val)!
		action.done = true
	}

	// done_delete actions
	mut done_delete_actions := plbook.find(filter: 'osal.done_delete')!
	for mut action in done_delete_actions {
		mut p := action.params
		key := p.get('key')!
		
		console.print_header('Deleting done flag: ${key}')
		osal.done_delete(key)!
		action.done = true
	}

	// done_reset actions
	mut done_reset_actions := plbook.find(filter: 'osal.done_reset')!
	for mut action in done_reset_actions {
		console.print_header('Resetting all done flags')
		osal.done_reset()!
		action.done = true
	}

	// done_print actions
	mut done_print_actions := plbook.find(filter: 'osal.done_print')!
	for mut action in done_print_actions {
		console.print_header('Printing done flags')
		osal.done_print()!
		action.done = true
	}
}

fn play_env(mut plbook PlayBook) ! {
	// env_set actions
	mut env_set_actions := plbook.find(filter: 'osal.env_set')!
	for mut action in env_set_actions {
		mut p := action.params
		key := p.get('key')!
		value := p.get('value')!
		overwrite := p.get_default_true('overwrite')
		
		console.print_header('Setting environment variable: ${key}')
		osal.env_set(
			key: key
			value: value
			overwrite: overwrite
		)
		action.done = true
	}

	// env_unset actions
	mut env_unset_actions := plbook.find(filter: 'osal.env_unset')!
	for mut action in env_unset_actions {
		mut p := action.params
		key := p.get('key')!
		
		console.print_header('Unsetting environment variable: ${key}')
		osal.env_unset(key)
		action.done = true
	}

	// env_set_all actions
	mut env_set_all_actions := plbook.find(filter: 'osal.env_set_all')!
	for mut action in env_set_all_actions {
		mut p := action.params
		
		// Parse environment variables from parameters
		mut env_vars := map[string]string{}
		// Get all parameters and filter out the control parameters
		params_map := p.get_map()
		for key, value in params_map {
			if key !in ['clear_before_set', 'overwrite_if_exists'] {
				env_vars[key] = value
			}
		}
		
		clear_before_set := p.get_default_false('clear_before_set')
		overwrite_if_exists := p.get_default_true('overwrite_if_exists')
		
		console.print_header('Setting multiple environment variables')
		osal.env_set_all(
			env: env_vars
			clear_before_set: clear_before_set
			overwrite_if_exists: overwrite_if_exists
		)
		action.done = true
	}

	// env_load_file actions
	mut env_load_file_actions := plbook.find(filter: 'osal.env_load_file')!
	for mut action in env_load_file_actions {
		mut p := action.params
		file_path := p.get('file_path')!
		
		console.print_header('Loading environment from file: ${file_path}')
		osal.load_env_file(file_path)!
		action.done = true
	}
}

fn play_exec(mut plbook PlayBook) ! {
	// exec actions
	mut exec_actions := plbook.find(filter: 'osal.exec')!
	for mut action in exec_actions {
		mut p := action.params
		
		cmd := p.get('cmd')!
		
		mut command := osal.Command{
			cmd: cmd
			name: p.get_default('name', '')!
			description: p.get_default('description', '')!
			timeout: p.get_int_default('timeout', 3600)!
			stdout: p.get_default_true('stdout')
			stdout_log: p.get_default_true('stdout_log')
			raise_error: p.get_default_true('raise_error')
			ignore_error: p.get_default_false('ignore_error')
			work_folder: p.get_default('work_folder', '')!
			retry: p.get_int_default('retry', 0)!
			interactive: p.get_default_true('interactive')
			debug: p.get_default_false('debug')
		}
		
		// Parse environment variables if provided
		if p.exists('environment') {
			env_str := p.get('environment')!
			// Parse environment string (format: "KEY1=value1,KEY2=value2")
			env_pairs := env_str.split(',')
			mut env_map := map[string]string{}
			for pair in env_pairs {
				if pair.contains('=') {
					key := pair.all_before('=').trim_space()
					value := pair.all_after('=').trim_space()
					env_map[key] = value
				}
			}
			command.environment = env_map.clone()
		}
		
		// Parse ignore_error_codes if provided
		if p.exists('ignore_error_codes') {
			ignore_codes := p.get_list_int('ignore_error_codes')!
			command.ignore_error_codes = ignore_codes
		}
		
		console.print_header('Executing command: ${cmd}')
		osal.exec(command)!
		action.done = true
	}

	// exec_silent actions
	mut exec_silent_actions := plbook.find(filter: 'osal.exec_silent')!
	for mut action in exec_silent_actions {
		mut p := action.params
		cmd := p.get('cmd')!
		
		console.print_header('Executing command silently: ${cmd}')
		osal.execute_silent(cmd)!
		action.done = true
	}

	// exec_interactive actions
	mut exec_interactive_actions := plbook.find(filter: 'osal.exec_interactive')!
	for mut action in exec_interactive_actions {
		mut p := action.params
		cmd := p.get('cmd')!
		
		console.print_header('Executing command interactively: ${cmd}')
		osal.execute_interactive(cmd)!
		action.done = true
	}
}

fn play_package(mut plbook PlayBook) ! {
	// package_refresh actions
	mut package_refresh_actions := plbook.find(filter: 'osal.package_refresh')!
	for mut action in package_refresh_actions {
		console.print_header('Refreshing package lists')
		osal.package_refresh()!
		action.done = true
	}

	// package_install actions
	mut package_install_actions := plbook.find(filter: 'osal.package_install')!
	for mut action in package_install_actions {
		mut p := action.params
		
		// Support both 'name' parameter and arguments
		mut packages := []string{}
		
		if p.exists('name') {
			packages << p.get('name')!
		}
		
		// Add any arguments (packages without keys)
		mut i := 0
		for {
			arg := p.get_arg_default(i, '')!
			if arg == '' {
				break
			}
			packages << arg
			i++
		}
		
		for package in packages {
			if package != '' {
				console.print_header('Installing package: ${package}')
				osal.package_install(package)!
			}
		}
		action.done = true
	}

	// package_remove actions
	mut package_remove_actions := plbook.find(filter: 'osal.package_remove')!
	for mut action in package_remove_actions {
		mut p := action.params
		
		// Support both 'name' parameter and arguments
		mut packages := []string{}
		
		if p.exists('name') {
			packages << p.get('name')!
		}
		
		// Add any arguments (packages without keys)
		mut i := 0
		for {
			arg := p.get_arg_default(i, '')!
			if arg == '' {
				break
			}
			packages << arg
			i++
		}
		
		for package in packages {
			if package != '' {
				console.print_header('Removing package: ${package}')
				osal.package_remove(package)!
			}
		}
		action.done = true
	}
}