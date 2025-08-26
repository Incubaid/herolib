module sshagent

import os
import freeflowuniverse.herolib.core.pathlib

@[params]
pub struct SSHAgentNewArgs {
pub mut:
	homepath string
}

pub fn new(args_ SSHAgentNewArgs) !SSHAgent {
	mut args := args_
	if args.homepath.len == 0 {
		args.homepath = '${os.home_dir()}/.ssh'
	}

	mut agent := SSHAgent{
		homepath: pathlib.get_dir(path: args.homepath, create: true)!
	}
	res := os.execute('ssh-add -l')
	if res.exit_code == 0 {
		agent.active = true
	}
	agent.init()! // loads the keys known on fs and in ssh-agent
	return agent
}

pub fn loaded() bool {
	mut agent := new() or { return false }
	return agent.active
}

// create new SSH agent with single instance guarantee
pub fn new_single(args_ SSHAgentNewArgs) !SSHAgent {
	mut agent := new(args_)!
	agent.ensure_single_agent()!
	return agent
}

// check if SSH agent is properly configured and running
pub fn agent_status() !map[string]string {
	mut agent := new()!
	return agent.diagnostics()
}
