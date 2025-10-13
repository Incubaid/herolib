module generic

import incubaid.herolib.ui.console { UIConsole }
// import incubaid.herolib.ui.telegram { UITelegram }
import incubaid.herolib.ui.uimodel { DropDownArgs }

// return the dropdown as an int
// 	description string
// 	items       []string
// 	warning     string
// 	clear       bool = true
pub fn (mut c UserInterface) ask_dropdown(args DropDownArgs) !string {
	match mut c.channel {
		UIConsole { return c.channel.ask_dropdown(args)! }
		else { panic("can't find channel") }
	}
}

// result can be multiple, aloso can select all
// 	description string
// 	items       []string
// 	warning     string
// 	clear       bool = true
pub fn (mut c UserInterface) ask_dropdown_multiple(args DropDownArgs) ![]string {
	match mut c.channel {
		UIConsole {
			return c.channel.ask_dropdown_multiple(args)!
		}
		else {
			panic("can't find channel")
		}
	}
}

// will return the string as given as response
// 	description string
// 	items       []string
// 	warning     string
// 	clear       bool = true
pub fn (mut c UserInterface) ask_dropdown_int(args DropDownArgs) !int {
	match mut c.channel {
		UIConsole {
			return c.channel.ask_dropdown_int(args)!
		}
		else {
			panic("can't find channel")
		}
	}
}
