module startupmanager

import incubaid.herolib.ui.console
import incubaid.herolib.osal.screen
import incubaid.herolib.osal.systemd
// import incubaid.herolib.osal.zinit // Comment or remove this line
import incubaid.herolib.clients.zinit // Add this line

pub struct StartupManager {
pub mut:
	cat StartupManagerType
}

pub fn get(cat StartupManagerType) !StartupManager {
	console.print_debug('startupmanager (factory): get ${cat}')
	mut sm := StartupManager{
		cat: cat
	}
	match sm.cat {
		.zinit {
			mut zinit_client_test := zinit.get()! // 'create:true' ensures a client object is initiated even if the socket isn't active.
			if _ := zinit_client_test.rpc_discover() {
				sm.cat = .zinit
			} else {
				return error('zinit not found ${err}')
			}

		}
		.auto {
			// Try to get a ZinitRPC client and check if it can discover RPC methods.
			// This implies the zinit daemon is running and accessible via its socket.
			// Since it's auto doesn't insist and die if it can't find zinit.
			mut zinit_client_test := zinit.get(create: true)! // 'create:true' ensures a client object is initiated even if the socket isn't active.
			if _ := zinit_client_test.rpc_discover() {
				sm.cat = .zinit
			} else {
				sm.cat = .screen
			}
		} 
		.unknown {
			print_backtrace()
			return error("can't determine startup manager type, need to be a known one.")
		}
		else {
			return sm
		}
	}
	return sm
}

// launch a new process
//```
// name        string            @[required]
// cmd         string            @[required]
// cmd_stop    string
// cmd_test    string 		//command line to test service is running
// status  ZProcessStatus
// pid     int
// after   []string 	//list of service we depend on
// env     map[string]string
// oneshot bool
// start 	  bool = true
// restart     bool = true // whether the process should be restarted on failure
// description string //not used in zinit
//```
pub fn (mut sm StartupManager) new(args ZProcessNewArgs) ! {
	console.print_debug("startupmanager new:${args.name} cmd:'${args.cmd}' restart:${args.restart}")
	mut mycat := sm.cat
	match mycat {
		.screen {
			mut scr := screen.new(reset: false)!
			console.print_debug('screen startup manager ${args.name} cmd:${args.cmd}')
			_ = scr.add(name: args.name, cmd: args.cmd, reset: args.restart)!
			// because of how screen works the start is immediate
		}
		.systemd {
			// console.print_debug('systemd start  ${args.name}')
			mut systemdfactory := systemd.new()!
			systemdfactory.new(
				cmd:     args.cmd
				name:    args.name
				start:   args.start
				restart: args.restart
				env:     args.env
			)!
		}
		.zinit {
			console.print_debug('startupmanager: zinit process create ${args.name}.')
			// Get the Zinit RPC client instance.
			// We assume it's properly configured (e.g., socket_path) via its factory setup.
			mut zinit_client := zinit.get(create: true)!

			// Map ZProcessNewArgs to zinit.ServiceConfig
			mut service_config := zinit.ServiceConfig{
				exec:             args.cmd
				test:             args.cmd_test // Direct mapping
				oneshot:          args.oneshot  // Use the oneshot flag directly
				after:            args.after    // Direct mapping
				log:              'ring'
				env:              args.env     // Direct mapping
				dir:              args.workdir // Direct mapping
				shutdown_timeout: 0            // Default, or add to ZProcessNewArgs if needed
			}

			// Create the service configuration file in zinit
			zinit_client.service_create(args.name, service_config) or {
				return error('startupmanager: failed to create zinit service ${args.name}: ${err}')
			}
		}
		else {
			panic('to implement, startup manager only support screen & systemd for now: ${mycat}')
		}
	}
	// If 'start' is true, also monitor and start the service
	if args.start {
		sm.start(args.name)!
	}
}

pub fn (mut sm StartupManager) start(name string) ! {
	match sm.cat {
		.screen {
			return
		}
		.systemd {
			console.print_debug('startupmanager: systemd process start ${name}')
			mut systemdfactory := systemd.new()!
			if systemdfactory.exists(name) {
				// console.print_header("*************")
				mut systemdprocess := systemdfactory.get(name)!
				systemdprocess.start()!
			} else {
				return error('process in systemd with name ${name} not found')
			}
		}
		.zinit {
			console.print_debug('startupmanager: zinit process start ${name}')
			mut zinit_client := zinit.get()! // Get the already configured zinit client
			zinit_client.service_start(name) or {
				return error('startupmanager: Failed to start zinit service ${name}: ${err}')
			}
			// Monitor loads the config, if it's new it starts it.
			// If the service is already managed, this will bring it back up.
			zinit_client.service_monitor(name) or {
				return error('startupmanager: Failed to monitor zinit service ${name}: ${err}')
			}
		}
		else {
			panic('to implement, startup manager only support screen, systemd and zinit for now')
		}
	}
}

pub fn (mut sm StartupManager) stop(name string) ! {
	match sm.cat {
		.screen {
			mut screen_factory := screen.new(reset: false)!
			mut scr := screen_factory.get(name) or { return }
			scr.cmd_send('^C')!
			screen_factory.kill(name)!
		}
		.systemd {
			console.print_debug('systemd stop ${name}')
			mut systemdfactory := systemd.new()!
			if systemdfactory.exists(name) {
				mut systemdprocess := systemdfactory.get(name)!
				systemdprocess.stop()!
			}
		}
		.zinit {
			console.print_debug('zinit stop ${name} using clients.zinit')
			mut zinit_client := zinit.get()! // Get the already configured zinit client
			zinit_client.service_stop(name) or {
				return error('Failed to stop zinit service ${name}: ${err}')
			}
		}
		else {
			panic('to implement, startup manager only support screen for now')
		}
	}
}

// kill the process by name
pub fn (mut sm StartupManager) restart(name string) ! {
	match sm.cat {
		.screen {
			panic('implement')
		}
		.systemd {
			console.print_debug('systemd restart ${name}')
			mut systemdfactory := systemd.new()!
			mut systemdprocess := systemdfactory.get(name)!
			systemdprocess.restart()!
		}
		.zinit {
			console.print_debug('zinit restart ${name} using clients.zinit')
			mut zinit_client := zinit.get()! // Get the already configured zinit client
			// Zinit's 'start' method can act as a restart if the service is already running.
			// For a clean restart, you might explicitly stop and then start, but service_start
			// in Zinit is generally idempotent and will manage the state.
			zinit_client.service_stop(name) or {}
			zinit_client.service_start(name) or {
				return error('Failed to restart zinit service ${name}: ${err}')
			}
		}
		else {
			panic('to implement, startup manager only support screen for now')
		}
	}
}

// remove from the startup manager
pub fn (mut sm StartupManager) delete(name string) ! {
	match sm.cat {
		.screen {
			mut screen_factory := screen.new(reset: false)!
			mut scr := screen_factory.get(name) or { return }
			scr.cmd_send('^C')!
			screen_factory.kill(name)!
		}
		.systemd {
			mut systemdfactory := systemd.new()!
			mut systemdprocess := systemdfactory.get(name)!
			systemdprocess.delete()!
		}
		.zinit {
			console.print_debug('zinit delete ${name} using clients.zinit')
			mut zinit_client := zinit.get()! // Get the already configured zinit client
			// To properly delete, first stop monitoring and then stop the service, before deleting the configuration.
			zinit_client.service_forget(name) or {}
			zinit_client.service_stop(name) or {}
			zinit_client.service_delete(name) or {
				return error('Failed to delete zinit service ${name}: ${err}')
			}
		}
		else {
			panic('to implement, startup manager only support screen & systemd for now  ${sm.cat}')
		}
	}
}

pub enum ProcessStatus {
	unknown
	active
	inactive
	failed
	activating
	deactivating
}

// remove from the startup manager
pub fn (mut sm StartupManager) status(name string) !ProcessStatus {
	match sm.cat {
		.screen {
			mut screen_factory := screen.new(reset: false)!
			mut scr := screen_factory.get(name) or {
				return error('startup manager: failed to get status of process ${name}\n${err} in screen.')
			}
			match scr.status()! {
				.active { return .active }
				.inactive { return .inactive }
				.unknown { return .unknown }
			}
		}
		.systemd {
			mut systemdfactory := systemd.new()!
			mut systemdprocess := systemdfactory.get(name) or { return .unknown }
			systemd_status := systemdprocess.status() or {
				return error('startup manager: failed to get status of process ${name}\n${err} in systemd.')
			}
			s := ProcessStatus.from(systemd_status.str())!
			return s
		}
		.zinit {
			console.print_debug('startup manager: zinit status ${name}.')
			mut zinit_client := zinit.get()!
			// Attempt to get the service status. Handle "Service not found" as .unknown.
			status_info := zinit_client.service_status(name) or {
				err_val := err.msg().to_lower()
				if err_val.contains('service not found') {
					return .unknown
				} else {
					return error('startup manager: failed to get status of process ${name}\n${err} in zinit.')
				}
			}

			// Map Zinit's ServiceStatus.state to StartupManager's ProcessStatus
			match status_info.state.to_lower() {
				'running', 'success' {
					return .active
				} // Zinit considers 'success' for one-shot tasks as complete & successful
				'error', 'broken' {
					return .failed
				}
				'starting' {
					return .activating
				}
				'stopping' {
					return .deactivating
				}
				// Zinit has other states like 'paused', 'restarting', 'waiting', etc.
				// We'll map them to closest equivalents or .unknown for now.
				'stopped', 'restarted', 'forgotten' {
					return .inactive
				} // 'restarted' here means it's about to be 'running' again, but in the context of a single status check it might be transient. For simplicity map it to inactive here.
				else {
					console.print_debug('startup manager: unknown zinit state for ${name}: ${status_info.state} zinit')
					return .unknown
				}
			}
		}
		else {
			panic('to implement, startup manager only support screen & systemd for now  ${sm.cat}')
		}
	}
}

pub fn (mut sm StartupManager) running(name string) !bool {
	if !sm.exists(name)! {
		return false
	}
	mut s := sm.status(name)!
	return s == .active
}

// remove from the startup manager
pub fn (mut sm StartupManager) output(name string) !string {
	match sm.cat {
		.screen {
			panic('implement')
		}
		.systemd {
			return systemd.journalctl(service: name)!
		}
		.zinit {
			console.print_debug('zinit output ${name} using clients.zinit')
			mut zinit_client := zinit.get()!
			// Calls stream_current_logs with a name filter.
			logs := zinit_client.stream_current_logs(zinit.LogParams{ name: name }) or {
				return error('Failed to get zinit logs for ${name}: ${err}')
			}
			return logs.join('\n')
		}
		else {
			panic('to implement, startup manager only support screen & systemd for now  ${sm.cat}')
		}
	}
}

pub fn (mut sm StartupManager) exists(name string) !bool {
	if sm.cat == .unknown {
		// If type is auto/unknown, try to determine.
		mut zinit_client_test := zinit.get(create: true)!
		if _ := zinit_client_test.rpc_discover() {
			sm.cat = .zinit
		} else {
			sm.cat = .screen
		}
	}
	match sm.cat {
		.screen {
			mut scr := screen.new(reset: false) or { panic("can't get screen") }
			return scr.exists(name)
		}
		.systemd {
			// console.print_debug("exists sm systemd ${name}")
			mut systemdfactory := systemd.new()!
			return systemdfactory.exists(name)
		}
		.zinit {
			console.print_debug('zinit exists ${name} using clients.zinit')
			mut zinit_client := zinit.get(create: true)!
			zinit_client.service_status(name) or { return false }
			return true
		}
		else {
			panic('to implement. startup manager only support screen & systemd for now  ${sm.cat}')
		}
	}
}

// list all services as known to the startup manager
pub fn (mut sm StartupManager) list() ![]string {
	match sm.cat {
		.screen {
			// mut scr := screen.new(reset: false) or { panic("can't get screen") }
			panic('implement')
		}
		.systemd {
			mut systemdfactory := systemd.new()!
			return systemdfactory.names()
		}
		.zinit {
			console.print_debug('zinit list using clients.zinit')
			mut zinit_client := zinit.get()!
			// service_list returns a map[string]string (name -> state). We only need the names.
			service_map := zinit_client.service_list() or {
				return error('Failed to list zinit services: ${err}')
			}
			mut names := []string{}
			for name in service_map.keys() {
				names << name
			}
			return names
		}
		else {
			panic('to implement. startup manager only support screen & systemd for now:  ${sm.cat}')
		}
	}
}
