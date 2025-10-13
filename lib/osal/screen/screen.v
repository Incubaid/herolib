module screen

import incubaid.herolib.ui.console
import incubaid.herolib.osal.core as osal
import incubaid.herolib.core
import os
import time

@[heap]
pub struct Screen {
pub mut:
	cmd   string
	name  string
	pid   int
	state ScreenState
	// factory ?&ScreensFactory @[skip; str: skip]
}

pub enum ScreenState {
	unknown
	detached
}

pub enum ScreenStatus {
	unknown
	active
	inactive
}

// Method to check the status of a screen process
pub fn (self Screen) status() !ScreenStatus {
	// Command to list screen sessions
	cmd := 'screen -ls'

	ls_response := os.execute(cmd)
	if ls_response.exit_code != 0 {
		if ls_response.output.contains('No Sockets found') {
			return .inactive
		}

		return error('failed to list screen sessions: ${ls_response.output}')
	}

	// Check if the screen session exists by looking for the session name in the output
	if !ls_response.output.contains(self.name) {
		return .inactive
	}

	// Command to send a dummy command to the screen session and check response
	cmd_check := "screen -S ${self.name} -X stuff $'\003' && sleep 0.1 && screen -S ${self.name} -X stuff $'ps\n'"
	osal.execute_silent(cmd_check)!
	time.sleep(100 * time.millisecond)
	// Command to check if there is an active process in the screen session
	cmd_ps := 'screen -S ${self.name} -X hardcopy -h /tmp/screen_output; cat /tmp/screen_output'
	ps_response := osal.execute_silent(cmd_ps)!

	// Parse the response and determine if there's an active process
	return parse_screen_process_status(ps_response)
}

// Function to parse the screen process status output
fn parse_screen_process_status(output string) ScreenStatus {
	lines := output.split_into_lines()

	// Check the output for active processes
	for line in lines {
		if line.contains('SCREEN') || line.contains('PID') {
			return .active
		}
	}

	// If no active process is found, return inactive
	return .inactive
}

fn (mut self Screen) kill_() ! {
	// console.print_debug('kill screen: ${self}')
	if self.pid == 0 || self.pid < 5 {
		return error("pid was <5 for ${self}, can't kill")
	}
	osal.process_kill_recursive(pid: self.pid)!
	res := os.execute('export TERM=xterm-color && screen -X -S ${self.name} kill > /dev/null 2>&1')
	if res.exit_code > 1 {
		return error('could not kill a screen.\n${res.output}')
	}
	time.sleep(100 * time.millisecond) // 0.1 sec wait
	os.execute('screen -wipe  > /dev/null 2>&1')
	// self.scan()!
}

// fn (mut self Screen) scan() ! {
// 	mut f:=self.factory or {panic("bug, no factory attached to screen.")}
// 	f.scan(false)!
// }

pub fn (mut self Screen) attach() ! {
	cmd := 'screen -r ${self.pid}.${self.name}'
	osal.execute_interactive(cmd)!
}

pub fn (mut self Screen) cmd_send(cmd string) ! {
	mut cmd2 := "screen -S ${self.name} -p 0 -X stuff \"${cmd} \n\" "
	if core.is_osx()! {
		cmd2 = "screen -S ${self.name} -p 0 -X stuff \"${cmd}\"\$'\n' "
	}
	res := os.execute(cmd2)
	if res.exit_code > 1 {
		return error('could not send screen command.\n${cmd2}\n${res.output}')
	}
}

pub fn (mut self Screen) str() string {
	green := console.color_fg(.green)
	yellow := console.color_fg(.yellow)
	reset := console.reset
	return ' - screen:${green}${self.name:-20}${reset} pid:${yellow}${self.pid:-10}${reset} state:${green}${self.state}${reset}'
}

fn (mut self Screen) start_() ! {
	if self.pid != 0 {
		return
	}
	if self.name.len == 0 {
		return error('screen name needs to exist.')
	}
	if self.cmd == '' {
		self.cmd = '/bin/bash'
	}
	cmd := 'export TERM=xterm-color && screen -dmS ${self.name} ${self.cmd}'
	// console.print_debug(" startcmd:'${cmd}'")
	res := os.execute(cmd)
	// console.print_debug(res)
	if res.exit_code > 1 {
		return error('could not find screen or other error, make sure screen is installed.\n${res.output}')
	}
}
