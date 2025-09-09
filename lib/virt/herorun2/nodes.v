module herorun2

import freeflowuniverse.herolib.osal.sshagent

// Node-related structs and functionality
pub struct NodeSettings {
pub:
	node_ip string
	user    string
}

pub struct Node {
pub:
	settings NodeSettings
}

@[params]
pub struct NewNodeArgs {
pub:
	node_ip string
	user    string
}

@[params]
pub struct NodeConnectArgs {
pub:
	keyname string @[required]
}

// Node information struct
pub struct NodeInfo {
pub:
	ip       string
	user     string
	provider string
	status   string
}

// Create new node
pub fn new_node(args NewNodeArgs) Node {
	return Node{
		settings: NodeSettings{
			node_ip: args.node_ip
			user:    args.user
		}
	}
}

// User configuration for SSH
pub struct UserConfig {
pub:
	keyname string
}

@[params]
pub struct NewUserArgs {
pub:
	keyname string @[required]
}

// Create new user with SSH agent setup
pub fn new_user(args NewUserArgs) !UserConfig {
	mut agent := sshagent.new_single()!
	// Silent check - just ensure agent is working without verbose output
	if !agent.is_agent_responsive() {
		return error('SSH agent is not responsive')
	}
	agent.init()!
	return UserConfig{
		keyname: args.keyname
	}
}
