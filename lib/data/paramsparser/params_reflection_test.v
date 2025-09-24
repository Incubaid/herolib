module paramsparser

import time

struct TestStruct {
	name     string
	nick     ?string
	birthday time.Time
	number   int
	yesno    bool
	liststr  []string
	listint  []int
	listbool []bool
	listu32  []u32
	child    TestChild
}

struct TestChild {
	child_name     string
	child_number   int
	child_yesno    bool
	child_liststr  []string
	child_listint  []int
	child_listbool []bool
	child_listu32  []u32
}

const test_child = TestChild{
	child_name:     'test_child'
	child_number:   3
	child_yesno:    false
	child_liststr:  ['three', 'four']
	child_listint:  [3, 4]
	child_listbool: [true, false]
	child_listu32:  [u32(5), u32(6)]
}

const test_struct = TestStruct{
	name:     'test'
	birthday: time.new(
		day:   12
		month: 12
		year:  2012
	)
	number:   2
	yesno:    true
	liststr:  ['one', 'two']
	listint:  [1, 2]
	listbool: [true, false]
	listu32:  [u32(7), u32(8)]
	child:    test_child
}

const test_child_params = Params{
	params: [
		Param{
			key:   'child_name'
			value: 'test_child'
		},
		Param{
			key:   'child_number'
			value: '3'
		},
		Param{
			key:   'child_yesno'
			value: 'false'
		},
		Param{
			key:   'child_liststr'
			value: 'three,four'
		},
		Param{
			key:   'child_listint'
			value: '3,4'
		},
		Param{
			key:   'child_listbool'
			value: 'true,false'
		},
		Param{
			key:   'child_listu32'
			value: '5,6'
		},
	]
}

const test_params = Params{
	params: [Param{
		key:   'name'
		value: 'test'
	}, Param{
		key:   'birthday'
		value: '2012-12-12 00:00:00'
	}, Param{
		key:   'number'
		value: '2'
	}, Param{
		key:   'yesno'
		value: 'true'
	}, Param{
		key:   'liststr'
		value: 'one,two'
	}, Param{
		key:   'listint'
		value: '1,2'
	}, Param{
		key:   'listbool'
		value: 'true,false'
	}, Param{
		key:   'listu32'
		value: '7,8'
	}, Param{
		key:   'child'
		value: test_child_params.export()
	}]
}

fn test_encode_struct() {
	encoded_struct := encode[TestStruct](test_struct)!
	assert encoded_struct == test_params
}

fn test_decode_struct() {
	decoded_struct := test_params.decode[TestStruct](TestStruct{})!
	assert decoded_struct.name == test_struct.name
	assert decoded_struct.birthday.day == test_struct.birthday.day
	assert decoded_struct.birthday.month == test_struct.birthday.month
	assert decoded_struct.birthday.year == test_struct.birthday.year
	assert decoded_struct.number == test_struct.number
	assert decoded_struct.yesno == test_struct.yesno
	assert decoded_struct.liststr == test_struct.liststr
	assert decoded_struct.listint == test_struct.listint
	assert decoded_struct.listbool == test_struct.listbool
	assert decoded_struct.listu32 == test_struct.listu32
	assert decoded_struct.child == test_struct.child
}

fn test_optional_field() {
	mut test_struct_with_nick := TestStruct{
		name:     test_struct.name
		nick:     'test_nick'
		birthday: test_struct.birthday
		number:   test_struct.number
		yesno:    test_struct.yesno
		liststr:  test_struct.liststr
		listint:  test_struct.listint
		listbool: test_struct.listbool
		listu32:  test_struct.listu32
		child:    test_struct.child
	}

	encoded_struct_with_nick := encode[TestStruct](test_struct_with_nick)!
	assert encoded_struct_with_nick.get('nick')! == 'test_nick'

	decoded_struct_with_nick := encoded_struct_with_nick.decode[TestStruct](TestStruct{})!
	assert decoded_struct_with_nick.nick or { '' } == 'test_nick'

	// Test decoding when optional field is not present in params
	mut params_without_nick := test_params
	params_without_nick.params = params_without_nick.params.filter(it.key != 'nick')
	decoded_struct_without_nick := params_without_nick.decode[TestStruct](TestStruct{})!
	assert decoded_struct_without_nick.nick == none
}

fn test_encode() {
	// test single level struct
	encoded_child := encode[TestChild](test_child)!
	assert encoded_child == test_child_params
}
