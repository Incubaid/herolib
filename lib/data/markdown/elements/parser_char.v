module elements

import os
// import incubaid.herolib.ui.console

// is a char parser

// error while parsing
struct ParserCharError {
mut:
	error  string
	charnr int
}

struct ParserChar {
mut:
	charnr int
	runes  []rune
	errors []ParserCharError
}

fn parser_char_new_path(path string) !ParserChar {
	if !os.exists(path) {
		return error("path: '${path}' does not exist, cannot parse.")
	}
	mut content := os.read_file(path) or { return error('Failed to load file ${path}') }
	return ParserChar{
		runes:  content.runes()
		charnr: 0
	}
}

pub fn parser_char_new_text(text string) ParserChar {
	return ParserChar{
		runes:  text.runes()
		charnr: 0
	}
}

// return a specific char
fn (mut parser ParserChar) error_add(msg string) {
	parser.errors << ParserCharError{
		error:  msg
		charnr: parser.charnr
	}
}

// return a specific char
fn (mut parser ParserChar) char(nr int) !string {
	if nr < 0 {
		return error('before file')
	}
	if parser.eof() {
		return ''
	}
	// V's substr operates on bytes, not runes.
	// To get a single rune, we access the runes slice directly.
	// The comment on line 57 was a strong hint.
	return parser.runes[nr].str()
}

// get current char
// will return error if out of scope
fn (mut parser ParserChar) char_current() string {
	return parser.char(parser.charnr) or { '' }
}

fn (mut parser ParserChar) forward(nr int) {
	parser.charnr += nr
}

// get next char, if end of file will return empty char
fn (mut parser ParserChar) char_next() string {
	if parser.eof() {
		return ''
	}
	return parser.char(parser.charnr + 1) or { panic(err) }
}

// if at start will return an empty char
fn (mut parser ParserChar) char_prev() string {
	if parser.charnr - 1 < 0 {
		return ''
	}
	return parser.char(parser.charnr - 1) or { panic(err) }
}

// check if starting from position we are on, offset is to count further
fn (mut parser ParserChar) text_next_is(tofind string, offset int) bool {
	startpos := parser.charnr + offset
	// Convert tofind to runes for accurate length comparison and slicing
	tofind_runes := tofind.runes()
	if startpos + tofind_runes.len > parser.runes.len {
		return false
	}
	// Extract the substring based on rune indices
	mut text_runes := parser.runes[startpos..startpos + tofind_runes.len]
	text := text_runes.string()
	didfind := (text == tofind)
	// console.print_debug(" -NT${offset}($tofind):'$text':$didfind .. ")
	return didfind
}

// check if previous text was, current possition does not count
// offset can be used to include current one (1 means current is last)
// fn (mut parser ParserChar) text_previous_is(tofind string, offset int) bool {
// 	startpos:=parser.charnr - tofind.len + offset
// 	if startpos <0 {
// 		return false
// 	}
// 	text := parser.chars.substr(startpos, startpos + tofind.len).replace("\n","\\n")
// 	console.print_debug(" -PT${offset}($tofind):'$text'")
// 	return text == tofind
// }
// FOR NOW NOT USED, IS BETTER TO FORCE EVERYONE TO USE text_next_is

// move further
fn (mut parser ParserChar) next() {
	parser.charnr += 1
}

// return true if end of file
fn (mut parser ParserChar) eof() bool {
	if parser.charnr > parser.runes.len - 1 {
		return true
	}
	return false
}
