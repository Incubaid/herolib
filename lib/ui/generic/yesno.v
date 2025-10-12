module generic

import incubaid.herolib.ui.console { UIConsole }
// import incubaid.herolib.ui.telegram { UITelegram }
import incubaid.herolib.ui.uimodel

// yes is true, no is false
// args:
// - description string
// - question string
// - warning string
// - clear bool = true
//
pub fn (mut c UserInterface) ask_yesno(args uimodel.YesNoArgs) !bool {
	match mut c.channel {
		UIConsole { return c.channel.ask_yesno(args)! }
		else { panic("can't find channel") }
	}
}
