module encoderhero

import freeflowuniverse.herolib.data.paramsparser
import time
import v.reflection

struct MyStruct {
	id   int
	name string
	// skip attributes would be best way how to do the encoding but can't get it to work
	other ?&Remark @[skip; str: skip]
}

// is the one we should skip
pub struct Remark {
	id int
}

fn test_encode() ! {
	mut o := MyStruct{
		id:    1
		name:  'test'
		other: &Remark{
			id: 123
		}
	}

	script := encode[MyStruct](o)!

	assert script.trim_space() == '!!define.my_struct id:1 name:test'

	println(script)

	o2 := decode[MyStruct](script)!

	assert o2 == MyStruct{
		id:   1
		name: 'test'
	}

	println(o2)
}
