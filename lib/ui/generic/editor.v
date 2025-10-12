module generic

// import incubaid.herolib.ui.console
// import incubaid.herolib.ui.telegram { UITelegram }
import incubaid.herolib.ui.uimodel

// open editor which can be used to edit content
// (not every UI has all capability, in case of console open vscode if installed) .
// .
// ```
// args:
// 	 content 	string //in specified format
//   cat ...
// enum InfoCat {
// 	content 	string //in specified format
// 	cat EditorCat
// }
// ```
// returns the editted content, idea is that formatting is used in editor
pub fn (mut c UserInterface) edit(args uimodel.EditArgs) !string {
	// match mut c.channel {
	// 	UIConsole { return c.channel.editor(args)! }
	// 	else { panic("can't find channel") }
	// }
	return ''
}
