module startupmanager

pub enum StartupManagerType {
	unknown
	screen
	zinit
	tmux
	systemd
	auto
}

@[params]
pub struct ZProcessNewArgs {
pub mut:
	name        string @[required]
	cmd         string @[required]
	cmd_stop    string   // command to stop (optional)
	cmd_test    string   // command line to test service is running
	workdir     string   // where to execute the commands
	after       []string // list of service we depend on
	env         map[string]string
	oneshot     bool
	start       bool = true
	restart     bool = true // whether the process should be restarted on failure
	description string // not used in zinit
	startuptype StartupManagerType
}

fn startup_manager_type_get(c string) StartupManagerType {
	match c {
		'unknown' { return .unknown }
		'screen' { return .screen }
		'zinit' { return .zinit }
		'tmux' { return .tmux }
		'systemd' { return .systemd }
		'auto' { return .auto }
		else { return .unknown }
	}
}
