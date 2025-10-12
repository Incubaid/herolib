module template

import incubaid.herolib.ui.console

pub fn clear() {
	console.print_debug('\033[2J')
}
