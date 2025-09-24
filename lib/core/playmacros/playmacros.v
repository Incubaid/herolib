module playmacros

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.playbook { Action, PlayBook }
import freeflowuniverse.herolib.threefold.grid4.gridsimulator
import freeflowuniverse.herolib.threefold.grid4.farmingsimulator
import freeflowuniverse.herolib.biz.bizmodel
import freeflowuniverse.herolib.biz.spreadsheet

pub fn play_actions(mut plbook PlayBook) ! {
	console.print_green('play actions (simulators)')
	farmingsimulator.play(mut plbook)!
	gridsimulator.play(mut plbook)!
	bizmodel.play(mut plbook)!
}

pub fn play_macro(action Action) !string {
	if action.actiontype != .macro {
		panic('should always be a macro')
	}
	console.print_green('macro: ${action.actor}:${action.name}')
	if action.actor == 'sheet' || action.actor == 'spreadsheet' {
		return spreadsheet.playmacro(action) or {
			return 'Macro error: ${action.actor}:${action.name}\n${err}'
		}
	} else if action.actor == 'tfgridsimulation_farming' {
		return farmingsimulator.playmacro(action) or {
			return 'Macro error: ${action.actor}:${action.name}\n${err}'
		}
	} else if action.actor == 'bizmodel' {
		return bizmodel.playmacro(action) or {
			return 'Macro error: ${action.actor}:${action.name}\n${err}'
		}
	} else {
		return "Macro error, Couldn't find macro: '${action.actor}:${action.name}'"
	}
	return ''
}
