module console

import freeflowuniverse.herolib.core.texttools

pub struct ConsoleFactory {
pub mut:
	consoles map[string]&UIConsole
	silent   bool
}

pub fn new_console_factory() &ConsoleFactory {
	return &ConsoleFactory{
		consoles: map[string]&UIConsole{}
		silent: false
	}
}

pub fn (mut cf ConsoleFactory) silent_set() {
	cf.silent = true
}

pub fn (mut cf ConsoleFactory) silent_unset() {
	cf.silent = false
}

pub fn (cf ConsoleFactory) silent_get() bool {
	return cf.silent
}

pub struct UIConsole {
pub mut:
	x_max      int = 80
	y_max      int = 60
	prev_lf    bool
	prev_title bool
	prev_item  bool
}

pub fn (mut c UIConsole) reset() {
	c.prev_lf = false
	c.prev_title = false
	c.prev_item = false
}

pub fn (mut c UIConsole) status() string {
	mut out := 'status: '
	if c.prev_lf {
		out += 'L '
	}
	if c.prev_title {
		out += 'T '
	}
	if c.prev_item {
		out += 'I '
	}
	return out.trim_space()
}

pub fn (mut cf ConsoleFactory) new_console() &UIConsole {
	mut c := UIConsole{}
	cf.consoles['main'] = &c
	return &c
}

pub fn (cf ConsoleFactory) get_console() &UIConsole {
	return cf.consoles['main'] or { panic('bug') }
}

pub fn trim(c_ string) string {
	c := texttools.remove_double_lines(c_)
	return c
}

// line feed
pub fn (mut cf ConsoleFactory) lf() {
	mut c := cf.get_console()
	if c.prev_lf {
		return
	}
	if !cf.silent_get() {
		print('\n')
	}
	c.prev_lf = true
}
