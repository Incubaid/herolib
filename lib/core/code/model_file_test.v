module code

fn test_parse_vfile() {
	code := "
module test

import os
import strings
import incubaid.herolib.core.texttools

const (
	VERSION = '1.0.0'
	DEBUG = true
)

pub struct Person {
pub mut:
	name string
	age  int
}

// greet returns a greeting message
pub fn (p Person) greet() string {
	return 'Hello, my name is \${p.name} and I am \${p.age} years old'
}

// create_person creates a new Person instance
pub fn create_person(name string, age int) Person {
	return Person{
		name: name
		age: age
	}
}
"

	vfile := parse_vfile(code) or {
		assert false, 'Failed to parse VFile: ${err}'
		return
	}

	// Test module name
	assert vfile.mod == 'test'

	// Test imports
	assert vfile.imports.len == 3
	assert vfile.imports[0].mod == 'os'
	assert vfile.imports[1].mod == 'strings'
	assert vfile.imports[2].mod == 'incubaid.herolib.core.texttools'

	// Test constants
	assert vfile.consts.len == 2
	assert vfile.consts[0].name == 'VERSION'
	assert vfile.consts[0].value == "'1.0.0'"
	assert vfile.consts[1].name == 'DEBUG'
	assert vfile.consts[1].value == 'true'

	// Test structs
	structs := vfile.structs()
	assert structs.len == 1
	assert structs[0].name == 'Person'
	assert structs[0].is_pub == true
	assert structs[0].fields.len == 2
	assert structs[0].fields[0].name == 'name'
	assert structs[0].fields[0].typ.vgen() == 'string'
	assert structs[0].fields[1].name == 'age'
	assert structs[0].fields[1].typ.vgen() == 'int'

	// Test functions
	functions := vfile.functions()
	assert functions.len == 2

	// Test method
	assert functions[0].name == 'greet'
	assert functions[0].is_pub == true
	assert functions[0].receiver.typ.vgen() == 'Person'
	assert functions[0].result.typ.vgen() == 'string'

	// Test standalone function
	assert functions[1].name == 'create_person'
	assert functions[1].is_pub == true
	assert functions[1].params.len == 2
	assert functions[1].params[0].name == 'name'
	assert functions[1].params[0].typ.vgen() == 'string'
	assert functions[1].params[1].name == 'age'
	assert functions[1].params[1].typ.vgen() == 'int'
	assert functions[1].result.typ.vgen() == 'Person'
}
