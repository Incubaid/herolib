module main

import incubaid.herolib.ui.console
import incubaid.herolib.ui.uimodel { DropDownArgs, QuestionArgs }

fn do() ! {
	mut c := console.new()

	r := c.ask_question(QuestionArgs{
		question: 'my question'
	})!
	println(r)

	r2 := c.ask_dropdown_multiple(DropDownArgs{
		description: 'my dropdown'
		items:       ['a', 'b', 'c']
	})!
	println(r2)

	r3 := c.ask_dropdown_multiple(DropDownArgs{
		description: 'my dropdown'
		items:       ['a', 'b', 'c']
		default:     ['a', 'b']
		clear:       true
	})!
	println(r3)

	r4 := c.ask_dropdown(DropDownArgs{
		description: 'my dropdown'
		items:       ['a', 'b', 'c']
		default:     ['c']
		clear:       true
	})!
	println(r4)
}

fn main() {
	do() or { panic(err) }
}
