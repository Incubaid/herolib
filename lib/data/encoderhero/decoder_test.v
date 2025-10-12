module encoderhero

import incubaid.herolib.data.ourtime

pub struct TestStruct {
	id   int
	name string
}

const blank_script = '!!define.teststruct'
const full_script = '!!define.teststruct id:42 name:testobject'
const invalid_script = '!!define.another_struct'

fn test_decode_simple() ! {
	mut object := decode[TestStruct](blank_script)!
	assert object == TestStruct{}

	object = decode[TestStruct](full_script)!
	assert object == TestStruct{
		id:   42
		name: 'testobject'
	}

	decode[TestStruct](invalid_script) or {
		assert true
		return
	}
	assert false // Should not reach here
}

pub struct ConfigStruct {
	name    string
	enabled bool
	timeout int = 30
	hosts   []string
}

const config_script = "!!define.configstruct name:production enabled:true timeout:60 hosts:'host1.com,host2.com,host3.com'"

fn test_decode_with_arrays() ! {
	object := decode[ConfigStruct](config_script)!
	assert object.name == 'production'
	assert object.enabled == true
	assert object.timeout == 60
	assert object.hosts.len == 3
	assert object.hosts[0] == 'host1.com'
}

pub struct Base {
	id      int
	version string
}

pub struct Person {
	Base  // Embedded struct
mut:
	name     string
	age      int
	birthday ourtime.OurTime
	active   bool = true
}

const person_heroscript = "!!define.person id:1 version:'1.0' name:Bob age:21 birthday:'2012-12-12 00:00:00' active:true"

const person = Person{
	id:       1
	version:  '1.0'
	name:     'Bob'
	age:      21
	birthday: ourtime.new('2012-12-12 00:00:00')!
	active:   true
}

fn test_decode_embedded() ! {
	object := decode[Person](person_heroscript)!
	assert object.id == person.id
	assert object.version == person.version
	assert object.name == person.name
	assert object.age == person.age
	assert object.active == person.active
}

fn test_decode_empty_fails() ! {
	decode[Person]('') or {
		assert true
		return
	}
	assert false // Should not reach here
}

fn test_decode_configure_format() ! {
	// Test alternative format with .configure instead of .define
	configure_script := '!!person.configure id:2 name:Alice age:30'
	object := decode[Person](configure_script)!
	assert object.id == 2
	assert object.name == 'Alice'
	assert object.age == 30
}