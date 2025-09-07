module herorun

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.tmux
import freeflowuniverse.herolib.osal.core as osal
import time
import freeflowuniverse.herolib.builder

// Container struct and related functionality
pub struct Container {
pub mut:
	name string
	//TODO: add properties we need for crun usage
	node ?builder.Node
	tmux ?tmux.Pane
	factory &ContainerFactory
}


pub fn (self Container) start() ! {

}


pub fn (self Container) stop() ! {

}

//execute command inside the container
pub fn (self Container) exec(args osal.ExecArgs) ! {
	//TODO: use same args as osal.exec but then run inside the builder.node, use self.node()!
	self.node()!.exec(args)!
}

//TODO: add whatever else we need


//return as enum
pub fn (self Container) status() !ContainerStatus {
	//TODO
}

pub enum ContainerStatus {
	running
	stopped
	paused
	unknown
}

//in percentage??? is that per core???
pub fn (self Container) cpu_usage() !f64 {
	//TODO
}

//in MByte
pub fn (self Container) mem_usage() !f64 {
	//TODO
}


pub struct TmuxPaneargs {
pub mut:
	window_name string
	pane_nr	int
	pane_name string //optional
	cmd string //optional, will execute this cmd
	reset bool //if true will reset everything and restart a cmd
	env map[string]string //optional, will set these env vars in the pane
}


//
pub fn (self Container) tmux_pane() !tmux.Pane {
	//TODO: check if tmux session exist, if not create if sessionname is given in factory
	//TODO: check if window exist, if not create
	//TODO: check if pane exist, if not create
}


//
pub fn (self Container) node() !builder.Node {
	//TODO: check if builder.Node is already there, if not initialize it and return
}