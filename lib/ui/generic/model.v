module generic

import incubaid.herolib.ui.console { UIConsole }
import incubaid.herolib.ui.template { UIExample }
// import incubaid.herolib.ui.telegram { UITelegram }

// need to do this for each type of UI channel e.g. console, telegram, ...
type UIChannel = UIConsole | UIExample // TODO TelegramBot

pub struct UserInterface {
pub mut:
	channel UIChannel
	user_id string
}

pub enum ChannelType {
	console
	telegram
}
