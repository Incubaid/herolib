module encoderhero

pub struct MyStruct {
	id    int
	name  string
	other ?&Remark @[skip]
}

pub struct Remark {
	id int
}

fn test_encode_skip() ! {
	mut o := MyStruct{
		id:    1
		name:  'test'
		other: &Remark{
			id: 123
		}
	}

	script := encode[MyStruct](o)!

	assert script.trim_space() == '!!define.my_struct id:1 name:test'
	assert !script.contains('other')

	o2 := decode[MyStruct](script)!

	assert o2.id == 1
	assert o2.name == 'test'
}

fn test_encode_skip_multiple_attrs() ! {
	struct SkipTest {
		id    int
		name  string
		skip1 string @[skip]
		skip2 int    @[other; skip]
		skip3 bool   @[skipdecode]
	}

	obj := SkipTest{
		id:    1
		name:  'test'
		skip1: 'should not appear'
		skip2: 999
		skip3: true
	}

	script := encode[SkipTest](obj)!

	assert script.contains('id:1')
	assert script.contains('name:test')
	assert !script.contains('skip1')
	assert !script.contains('skip2')
	assert script.contains('skip3')
}
