module elements

// Frontmatter2 struct
@[heap]
pub struct Frontmatter2 {
	DocBase
pub mut:
	args map[string]string
}

pub fn (mut self Frontmatter2) process() !int {
	if self.processed {
		return 0
	}
	for line in self.content.split_into_lines() {
		if line.trim_space() == '' {
			continue
		}
		if line.contains(':') {
			splitted := line.split(':')
			if splitted.len != 2 {
				return error('syntax error in frontmatter 2 in \n${self.content}')
			}
			pre := splitted[0].trim_space()
			post := splitted[1].trim_space().trim(' \'"').trim_space()
			self.args[pre] = post
		}
	}
	// Clear content after parsing
	self.content = ''
	self.processed = true
	return 1
}

pub fn (self Frontmatter2) markdown() !string {
	mut out := '---\n'
	for key, value in self.args {
		if value.contains(' ') {
			out += '${key} : \'${value}\'\n'
		} else {
			out += '${key} : ${value}\n'
		}
	}
	out += '---\n'
	return out
}

pub fn (self Frontmatter2) html() !string {
	mut out := '<div class="Frontmatter2">\n'
	for key, value in self.args {
		out += '  <p><strong>${key}</strong>: ${value}</p>\n'
	}
	out += '</div>'
	return out
}

pub fn (self Frontmatter2) pug() !string {
	mut out := ''
	out += 'div(class="Frontmatter2")\n'
	for key, value in self.args {
		out += '  p\n'
		out += '    strong ${key}: ${value}\n'
	}
	return out
}

pub fn (self Frontmatter2) get_string(key string) !string {
	// Retrieve a value using a query string
	return self.args[key] or { return error('Key "${key}" not found in Frontmatter2') }
}

pub fn (self Frontmatter2) get_bool(key string) !bool {
	return self.get_string(key)!.bool()
}

pub fn (self Frontmatter2) get_int(key string) !int {
	return self.get_string(key)!.int()
}
