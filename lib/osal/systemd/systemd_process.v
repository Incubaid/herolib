module systemd

// import os
import maps
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console
import os
import time

@[heap]
pub struct SystemdProcess {
pub mut:
	name        string
	unit        string // as generated or used by systemd
	cmd         string
	pid         int
	env         map[string]string
	systemd     &Systemd @[skip; str: skip]
	description string
	info        SystemdProcessInfo
	restart     bool = true // whether process will be restarted upon failure
}

pub fn (mut self SystemdProcess) servicefile_path() string {
	return '${self.systemd.path.path}/${self.name}.service'
}

pub fn (mut self SystemdProcess) write() ! {
	mut p := pathlib.get_file(path: self.servicefile_path(), create: true)!
	console.print_header(' systemd write service: ${p.path}')

	envs_lst := maps.to_array[string, string, string](self.env, fn (k string, v string) string {
		return 'Environment=${k}=${v}'
	})

	envs := envs_lst.join('\n')

	servicecontent := $tmpl('templates/service.yaml')

	p.write(servicecontent)!
}

pub fn (mut self SystemdProcess) start() ! {
	console.print_header('starting systemd process: ${self.name}')
	
	cmd := '
	systemctl daemon-reload
	systemctl enable ${self.name}
	systemctl start ${self.name}
	'
	
	job := osal.exec(cmd: cmd, stdout: false)!
	
	// Wait for service to start with timeout
	mut attempts := 0
	max_attempts := 10
	wait_interval := 500 // milliseconds
	
	for attempts < max_attempts {
		time.sleep(wait_interval * time.millisecond)
		status := self.status()!
		
		match status {
			.active {
				console.print_header('✓ systemd process started successfully: ${self.name}')
				self.refresh()!
				return
			}
			.failed {
				logs := self.get_logs(50)!
				return error('Service ${self.name} failed to start. Recent logs:\n${logs}')
			}
			.activating {
				attempts++
				continue
			}
			else {
				attempts++
				continue
			}
		}
	}
	
	// If we get here, service didn't start in time
	logs := self.get_logs(50)!
	return error('Service ${self.name} did not start within expected time. Status: ${self.status()!}. Recent logs:\n${logs}')

}

// get status from system
pub fn (mut self SystemdProcess) refresh() ! {
	self.systemd.load()!
	systemdobj2 := self.systemd.get(self.name)!
	self.info = systemdobj2.info
	self.description = systemdobj2.description
	self.name = systemdobj2.name
	self.unit = systemdobj2.unit
	self.cmd = systemdobj2.cmd
}

pub fn (mut self SystemdProcess) delete() ! {
	console.print_header('Process systemd: ${self.name} delete.')
	self.stop()!
	if os.exists(self.servicefile_path()) {
		os.rm(self.servicefile_path())!
	}
}

pub fn (mut self SystemdProcess) stop() ! {
	console.print_header('stopping systemd process: ${self.name}')
	
	cmd := '
	systemctl stop ${self.name}
	systemctl disable ${self.name}
	systemctl daemon-reload
	'
	
	_ = osal.exec(cmd: cmd, stdout: false, ignore_error: true)!
	
	// Wait for service to stop
	mut attempts := 0
	max_attempts := 10
	
	for attempts < max_attempts {
		time.sleep(500 * time.millisecond)
		status := self.status()!
		
		if status == .inactive {
			console.print_header('✓ systemd process stopped: ${self.name}')
			return
		}
		attempts++
	}
	
	console.print_header('⚠ systemd process may still be running: ${self.name}')
}

pub fn (mut self SystemdProcess) restart() ! {
	cmd := '
	systemctl daemon-reload
	systemctl restart ${self.name}
	'
	_ = osal.execute_silent(cmd)!
	self.systemd.load()!
}

enum SystemdStatus {
	unknown
	active
	inactive
	failed
	activating
	deactivating
}

pub fn (self SystemdProcess) get_logs(lines int) !string {
	return journalctl(service: self.name, limit: lines)
}

// Improve status method with better error handling
pub fn (self SystemdProcess) status() !SystemdStatus {
	cmd := 'systemctl is-active ${name_fix(self.name)}'
	
	job := osal.exec(cmd: cmd, stdout: false, ignore_error: true)!

	// console.print_debug("${cmd} \n***\n${job.output}\n***")
	
	match job.output.trim_space() {
		'active' { return .active }
		'inactive' { return .inactive }
		'failed' { return .failed }
		'activating' { return .activating }
		'deactivating' { return .deactivating }
		else { return .unknown }
	}
}

// Add detailed status method
pub fn (self SystemdProcess) status_detailed() !string {
	cmd := 'systemctl status --no-pager --lines=10 ${name_fix(self.name)}'
	job := osal.exec(cmd: cmd, stdout: false, ignore_error: true)!
	return job.output
}

