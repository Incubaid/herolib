module encoderhero

import incubaid.herolib.data.ourtime

pub struct Base {
	id      int
	version string
}

pub struct Person {
	Base  // Embedded struct
mut:
	name     string
	age      int = 20
	birthday ourtime.OurTime
	active   bool = true
	tags     []string
}

const person_heroscript = "!!define.person id:1 name:Bob active:true age:21 birthday:'2012-12-12 00:00' version:1.0"

const person = Person{
	id:       1
	version:  '1.0'
	name:     'Bob'
	age:      21
	birthday: ourtime.new('2012-12-12 00:00')!
	active:   true
}

fn test_encode_basic() ! {
	person_script := encode[Person](person)!
	assert person_script.trim_space() == person_heroscript.trim_space()
}

fn test_encode_with_arrays() ! {
	mut p := Person{
		id:   2
		name: 'Alice'
		age:  30
		tags: ['developer', 'manager', 'team-lead']
	}
	
	script := encode[Person](p)!
	assert script.contains('tags:developer,manager,team-lead')
	
	// Roundtrip test
	decoded := decode[Person](script)!
	assert decoded.tags.len == 3
	assert decoded.tags[0] == 'developer'
}

fn test_encode_defaults() ! {
	minimal := Person{
		id:   3
		name: 'Charlie'
	}
	
	script := encode[Person](minimal)!
	
	// Should include default values
	assert script.contains('age:20')
	assert script.contains('active:true')
}

struct Config {
mut:
	name    string
	timeout int
	enabled bool
	servers []string
	ports   []int
}

fn test_encode_config() ! {
	config := Config{
		name:    'production'
		timeout: 300
		enabled: true
		servers: ['srv1.com', 'srv2.com']
		ports:   [8080, 8081]
	}
	
	script := encode[Config](config)!
	
	assert script.contains('name:production')
	assert script.contains('timeout:300')
	assert script.contains('enabled:true')
	assert script.contains('servers:srv1.com,srv2.com')
	assert script.contains('ports:8080,8081')
	
	// Roundtrip
	decoded := decode[Config](script)!
	assert decoded.name == config.name
	assert decoded.servers.len == 2
	assert decoded.ports.len == 2
}

fn test_roundtrip() ! {
	original := Person{
		id:       99
		version:  '2.0'
		name:     'Test User'
		age:      25
		birthday: ourtime.now()
		active:   false
		tags:     ['tag1', 'tag2']
	}
	
	encoded := encode[Person](original)!
	decoded := decode[Person](encoded)!
	
	assert decoded.id == original.id
	assert decoded.version == original.version
	assert decoded.name == original.name
	assert decoded.age == original.age
	assert decoded.active == original.active
	assert decoded.tags.len == original.tags.len
}

// Test that nested structs are rejected
pub struct NestedChild {
	value string
}

pub struct NestedParent {
	name  string
	child NestedChild // This should cause an error
}

fn test_encode_nested_fails() ! {
	parent := NestedParent{
		name: 'parent'
		child: NestedChild{value: 'test'}
	}
	
	encode[NestedParent](parent) or {
		assert err.msg().contains('Nested structs are not supported')
		return
	}
	assert false // Should not reach here
}

// Test that arrays of structs are rejected
pub struct Item {
	name string
}

pub struct Container {
	items []Item // This should cause an error
}

fn test_encode_struct_array_fails() ! {
	container := Container{
		items: [Item{name: 'item1'}]
	}
	
	encode[Container](container) or {
		assert err.msg().contains('Unsupported field type for encoding: []encoderhero.Item')
		return
	}
	assert false // Should not reach here
}