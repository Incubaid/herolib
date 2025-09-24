module doctree

import freeflowuniverse.herolib.data.doctree.collection { Collection }
import freeflowuniverse.herolib.data.markdown.elements
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.core.playmacros

@[params]
pub struct MacroGetArgs {
pub mut:
	actor string
	name  string
}

// adds all action elements to a playbook, calls playmacros.play on the plbook,
// which processes the macros, then reprocesses every page with the actions' new content
pub fn (mut tree Tree) process_actions_and_macros() ! {
	console.print_green('Processing actions and macros')

	// first process the generic actions, which can be executed as is
	mut plbook := playbook.new()!
	for element_action in tree.get_actions()! {
		plbook.actions << &element_action.action
	}

	playmacros.play_actions(mut plbook)!

	// now get specific actions which need to return content
	mut ths := []thread !{}
	for _, mut col in tree.collections {
		ths << spawn fn (mut col Collection) ! {
			for _, mut page in col.pages {
				page.process_macros()! // calls play_macro in playmacros...
			}
		}(mut col)
	}

	for th in ths {
		th.wait()!
	}
}

fn (mut tree Tree) get_actions(args_ MacroGetArgs) ![]&elements.Action {
	// console.print_green('get actions for tree: name:${tree.name}')
	mut res := []&elements.Action{}
	for _, mut collection in tree.collections {
		// console.print_green("export collection: name:${name}")		
		for _, mut page in collection.pages {
			res << page.get_all_actions()!
		}
	}
	return res
}
