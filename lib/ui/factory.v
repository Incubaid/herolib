module ui

import incubaid.herolib.ui.generic { ChannelType, UserInterface }
import incubaid.herolib.ui.console
import incubaid.herolib.data.paramsparser
// import incubaid.herolib.ui.telegram

@[params]
pub struct UserInterfaceArgs {
pub mut:
	channel ChannelType
	params  paramsparser.Params // to pass arguments to implementation
}

pub fn new(args UserInterfaceArgs) !UserInterface {
	mut ch := match args.channel {
		.console { console.new() }
		else { panic("can't find channel") }
	}

	// .telegram { telegram.new() }

	return UserInterface{
		channel: ch
	}
	// return error("Channel type not understood, only console supported now.") // input is necessarily valid
}
