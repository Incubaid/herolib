module heromodels

import incubaid.herolib.hero.db
import incubaid.herolib.data.ourtime

fn test_planning_new() ! {
	// Initialize DBPlanning for testing
	mut mydb := db.new_test()!
	mut db_planning := DBPlanning{
		db: &mydb
	}

	// Test creating a new planning
	mut args := PlanningArg{
		name:                 'test_planning'
		description:          'Test planning for unit testing'
		color:                '#FF0000'
		timezone:             'UTC'
		is_public:            true
		calendar_template_id: 0
		registration_desk_id: 0
		autoschedule_rules:   []PlanningRecurrenceRule{}
		invite_rules:         []PlanningRecurrenceRule{}
		attendees_required:   []u32{}
		attendees_optional:   []u32{}
		securitypolicy:       0
		tags:                 []string{}
		messages:             []db.MessageArg{}
	}

	planning := db_planning.new(args)!

	assert planning.name == 'test_planning'
	assert planning.description == 'Test planning for unit testing'
	assert planning.color == '#FF0000'
	assert planning.timezone == 'UTC'
	assert planning.is_public == true
	assert planning.calendar_template_id == 0
	assert planning.registration_desk_id == 0
	assert planning.autoschedule_rules.len == 0
	assert planning.invite_rules.len == 0
	assert planning.attendees_required.len == 0
	assert planning.attendees_optional.len == 0
	assert planning.updated_at > 0

	println('✓ Planning new test passed!')
}

fn test_planning_crud_operations() ! {
	// Initialize DBPlanning for testing
	mut mydb := db.new_test()!
	mut db_planning := DBPlanning{
		db: &mydb
	}

	// Create a new planning
	mut args := PlanningArg{
		name:                 'crud_test_planning'
		description:          'Test planning for CRUD operations'
		color:                '#00FF00'
		timezone:             'EST'
		is_public:            false
		calendar_template_id: 1
		registration_desk_id: 10
		autoschedule_rules:   []PlanningRecurrenceRule{}
		invite_rules:         []PlanningRecurrenceRule{}
		attendees_required:   [u32(100), u32(101)]
		attendees_optional:   [u32(200)]
		securitypolicy:       0
		tags:                 []string{}
		messages:             []db.MessageArg{}
	}

	mut planning := db_planning.new(args)!

	// Create some recurrence rules
	mut rule1 := PlanningRecurrenceRule{
		until:       1893456000            // 2030-01-01
		by_weekday:  [u8(1), u8(3), u8(5)] // Monday, Wednesday, Friday
		by_monthday: []u8{}
		hour_from:   9
		hour_to:     17
		duration:    30
		priority:    5
	}

	mut rule2 := PlanningRecurrenceRule{
		until:       0
		by_weekday:  []u8{}
		by_monthday: [u8(1), u8(15)] // 1st and 15th of each month
		hour_from:   10
		hour_to:     12
		duration:    60
		priority:    8
	}

	planning.autoschedule_rules = [rule1]
	planning.invite_rules = [rule2]

	// Test set operation
	planning = db_planning.set(planning)!
	original_id := planning.id

	// Test get operation
	retrieved_planning := db_planning.get(original_id)!
	assert retrieved_planning.name == 'crud_test_planning'
	assert retrieved_planning.description == 'Test planning for CRUD operations'
	assert retrieved_planning.color == '#00FF00'
	assert retrieved_planning.timezone == 'EST'
	assert retrieved_planning.is_public == false
	assert retrieved_planning.calendar_template_id == 1
	assert retrieved_planning.registration_desk_id == 10
	assert retrieved_planning.attendees_required == [u32(100), u32(101)]
	assert retrieved_planning.attendees_optional == [u32(200)]
	assert retrieved_planning.id == original_id

	// Verify autoschedule_rules
	assert retrieved_planning.autoschedule_rules.len == 1
	assert retrieved_planning.autoschedule_rules[0].until == 1893456000
	assert retrieved_planning.autoschedule_rules[0].by_weekday == [u8(1), u8(3), u8(5)]
	assert retrieved_planning.autoschedule_rules[0].by_monthday.len == 0
	assert retrieved_planning.autoschedule_rules[0].hour_from == 9
	assert retrieved_planning.autoschedule_rules[0].hour_to == 17
	assert retrieved_planning.autoschedule_rules[0].duration == 30
	assert retrieved_planning.autoschedule_rules[0].priority == 5

	// Verify invite_rules
	assert retrieved_planning.invite_rules.len == 1
	assert retrieved_planning.invite_rules[0].until == 0
	assert retrieved_planning.invite_rules[0].by_weekday.len == 0
	assert retrieved_planning.invite_rules[0].by_monthday == [u8(1), u8(15)]
	assert retrieved_planning.invite_rules[0].hour_from == 10
	assert retrieved_planning.invite_rules[0].hour_to == 12
	assert retrieved_planning.invite_rules[0].duration == 60
	assert retrieved_planning.invite_rules[0].priority == 8

	// Test exist operation
	exists := db_planning.exist(original_id)!
	assert exists == true

	// Test update
	mut updated_args := PlanningArg{
		name:                 'updated_planning'
		description:          'Updated test planning'
		color:                '#0000FF'
		timezone:             'PST'
		is_public:            true
		calendar_template_id: 2
		registration_desk_id: 20
		autoschedule_rules:   []PlanningRecurrenceRule{}
		invite_rules:         []PlanningRecurrenceRule{}
		attendees_required:   [u32(102)]
		attendees_optional:   []u32{}
		securitypolicy:       0
		tags:                 []string{}
		messages:             []db.MessageArg{}
	}

	mut updated_planning := db_planning.new(updated_args)!
	updated_planning.id = original_id

	// Update rules
	mut updated_rule1 := PlanningRecurrenceRule{
		until:       1924992000     // 2031-01-01
		by_weekday:  [u8(2), u8(4)] // Tuesday, Thursday
		by_monthday: []u8{}
		hour_from:   8
		hour_to:     16
		duration:    45
		priority:    7
	}

	mut updated_rule2 := PlanningRecurrenceRule{
		until:       1956528000 // 2032-01-01
		by_weekday:  []u8{}
		by_monthday: [u8(5), u8(20)] // 5th and 20th of each month
		hour_from:   11
		hour_to:     13
		duration:    90
		priority:    3
	}

	updated_planning.autoschedule_rules = [updated_rule1]
	updated_planning.invite_rules = [updated_rule2]

	updated_planning = db_planning.set(updated_planning)!

	// Verify update
	final_planning := db_planning.get(original_id)!
	assert final_planning.name == 'updated_planning'
	assert final_planning.description == 'Updated test planning'
	assert final_planning.color == '#0000FF'
	assert final_planning.timezone == 'PST'
	assert final_planning.is_public == true
	assert final_planning.calendar_template_id == 2
	assert final_planning.registration_desk_id == 20
	assert final_planning.attendees_required == [u32(102)]
	assert final_planning.attendees_optional.len == 0

	// Verify updated autoschedule_rules
	assert final_planning.autoschedule_rules.len == 1
	assert final_planning.autoschedule_rules[0].until == 1924992000
	assert final_planning.autoschedule_rules[0].by_weekday == [u8(2), u8(4)]
	assert final_planning.autoschedule_rules[0].by_monthday.len == 0
	assert final_planning.autoschedule_rules[0].hour_from == 8
	assert final_planning.autoschedule_rules[0].hour_to == 16
	assert final_planning.autoschedule_rules[0].duration == 45
	assert final_planning.autoschedule_rules[0].priority == 7

	// Verify updated invite_rules
	assert final_planning.invite_rules.len == 1
	assert final_planning.invite_rules[0].until == 1956528000
	assert final_planning.invite_rules[0].by_weekday.len == 0
	assert final_planning.invite_rules[0].by_monthday == [u8(5), u8(20)]
	assert final_planning.invite_rules[0].hour_from == 11
	assert final_planning.invite_rules[0].hour_to == 13
	assert final_planning.invite_rules[0].duration == 90
	assert final_planning.invite_rules[0].priority == 3

	// Test delete operation
	db_planning.delete(original_id)!

	// Verify deletion
	exists_after_delete := db_planning.exist(original_id)!
	assert exists_after_delete == false

	println('✓ Planning CRUD operations test passed!')
}

fn test_planning_recurrence_rules_encoding_decoding() ! {
	// Initialize DBPlanning for testing
	mut mydb := db.new_test()!
	mut db_planning := DBPlanning{
		db: &mydb
	}

	// Create a new planning with recurrence rules
	mut args := PlanningArg{
		name:                 'recurrence_test_planning'
		description:          'Test planning for recurrence rules encoding/decoding'
		color:                '#FFFF00'
		timezone:             'UTC'
		is_public:            true
		calendar_template_id: 1
		registration_desk_id: 0
		autoschedule_rules:   []PlanningRecurrenceRule{}
		invite_rules:         []PlanningRecurrenceRule{}
		attendees_required:   []u32{}
		attendees_optional:   []u32{}
		securitypolicy:       0
		tags:                 []string{}
		messages:             []db.MessageArg{}
	}

	mut planning := db_planning.new(args)!
	planning.calendar_template_id = 1

	// Add complex recurrence rules
	mut rule1 := PlanningRecurrenceRule{
		until:       1893456000 // 2030-01-01
		by_weekday:  [u8(0), u8(1), u8(2), u8(3), u8(4), u8(5), u8(6)] // All days of week
		by_monthday: [u8(1), u8(2), u8(3), u8(4), u8(5), u8(6), u8(7), u8(8), u8(9), u8(10), u8(11),
			u8(12), u8(13), u8(14), u8(15), u8(16), u8(17), u8(18), u8(19), u8(20), u8(21), u8(22),
			u8(23), u8(24), u8(25), u8(26), u8(27), u8(28), u8(29), u8(30), u8(31)] // All days of month
		hour_from:   0
		hour_to:     23
		duration:    15
		priority:    10
	}

	mut rule2 := PlanningRecurrenceRule{
		until:       1924992000 // 2031-01-01
		by_weekday:  []u8{}
		by_monthday: []u8{}
		hour_from:   12
		hour_to:     13
		duration:    120
		priority:    1
	}

	planning.autoschedule_rules = [rule1, rule2]
	planning.invite_rules = [rule1]

	// Save the planning
	planning = db_planning.set(planning)!
	planning_id := planning.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_planning := db_planning.get(planning_id)!

	assert retrieved_planning.autoschedule_rules.len == 2
	assert retrieved_planning.invite_rules.len == 1

	// Verify first autoschedule rule details
	assert retrieved_planning.autoschedule_rules[0].until == 1893456000
	assert retrieved_planning.autoschedule_rules[0].by_weekday == [u8(0), u8(1), u8(2), u8(3),
		u8(4), u8(5), u8(6)]
	assert retrieved_planning.autoschedule_rules[0].by_monthday.len == 31
	assert retrieved_planning.autoschedule_rules[0].hour_from == 0
	assert retrieved_planning.autoschedule_rules[0].hour_to == 23
	assert retrieved_planning.autoschedule_rules[0].duration == 15
	assert retrieved_planning.autoschedule_rules[0].priority == 10

	// Verify second autoschedule rule details
	assert retrieved_planning.autoschedule_rules[1].until == 1924992000
	assert retrieved_planning.autoschedule_rules[1].by_weekday.len == 0
	assert retrieved_planning.autoschedule_rules[1].by_monthday.len == 0
	assert retrieved_planning.autoschedule_rules[1].hour_from == 12
	assert retrieved_planning.autoschedule_rules[1].hour_to == 13
	assert retrieved_planning.autoschedule_rules[1].duration == 120
	assert retrieved_planning.autoschedule_rules[1].priority == 1

	// Verify invite rule details
	assert retrieved_planning.invite_rules[0].until == 1893456000
	assert retrieved_planning.invite_rules[0].by_weekday == [u8(0), u8(1), u8(2), u8(3), u8(4),
		u8(5), u8(6)]
	assert retrieved_planning.invite_rules[0].by_monthday.len == 31
	assert retrieved_planning.invite_rules[0].hour_from == 0
	assert retrieved_planning.invite_rules[0].hour_to == 23
	assert retrieved_planning.invite_rules[0].duration == 15
	assert retrieved_planning.invite_rules[0].priority == 10

	println('✓ Planning recurrence rules encoding/decoding test passed!')
}

fn test_planning_type_name() ! {
	// Initialize DBPlanning for testing
	mut mydb := db.new_test()!
	mut db_planning := DBPlanning{
		db: &mydb
	}

	// Create a new planning
	mut args := PlanningArg{
		name:        'type_test_planning'
		description: 'Test planning for type name'
		color:       '#FF00FF'
		timezone:    'UTC'
		is_public:   true
	}

	planning := db_planning.new(args)!

	// Test type_name method
	type_name := planning.type_name()
	assert type_name == 'planning'

	println('✓ Planning type_name test passed!')
}

fn test_planning_description() ! {
	// Initialize DBPlanning for testing
	mut mydb := db.new_test()!
	mut db_planning := DBPlanning{
		db: &mydb
	}

	// Create a new planning
	mut args := PlanningArg{
		name:        'description_test_planning'
		description: 'Test planning for description'
		color:       '#00FFFF'
		timezone:    'UTC'
		is_public:   true
	}

	planning := db_planning.new(args)!

	// Test description method for each methodname
	assert planning.description('set') == 'Create or update a planning. Returns the ID of the planning.'
	assert planning.description('get') == 'Retrieve a planning by ID. Returns the planning object.'
	assert planning.description('delete') == 'Delete a planning by ID. Returns true if successful.'
	assert planning.description('exist') == 'Check if a planning exists by ID. Returns true or false.'
	assert planning.description('list') == 'List all plannings. Returns an array of planning objects.'
	assert planning.description('unknown') == 'This is generic method for the root object, TODO fill in, ...'

	println('✓ Planning description test passed!')
}

fn test_planning_example() ! {
	// Initialize DBPlanning for testing
	mut mydb := db.new_test()!
	mut db_planning := DBPlanning{
		db: &mydb
	}

	// Create a new planning
	mut args := PlanningArg{
		name:        'example_test_planning'
		description: 'Test planning for example'
		color:       '#AAAAAA'
		timezone:    'UTC'
		is_public:   true
	}

	planning := db_planning.new(args)!

	// Test example method for each methodname
	set_call, set_result := planning.example('set')
	assert set_call == '{"planning": {"name": "My Planning", "description": "A personal planning", "color": "#FF0000", "timezone": "UTC", "is_public": true, "calendar_template_id": 1, "registration_desk_id": 10, "autoschedule_rules": [{"until": 1893456000, "by_weekday": [1, 3, 5], "by_monthday": [], "hour_from": 9, "hour_to": 17, "duration": 30, "priority": 5}], "invite_rules": [{"until": 0, "by_weekday": [], "by_monthday": [1, 15], "hour_from": 10, "hour_to": 12, "duration": 60, "priority": 8}], "attendees_required": [100, 101], "attendees_optional": [200]}}'
	assert set_result == '1'

	get_call, get_result := planning.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"name": "My Planning", "description": "A personal planning", "color": "#FF0000", "timezone": "UTC", "is_public": true, "calendar_template_id": 1, "registration_desk_id": 10, "autoschedule_rules": [{"until": 1893456000, "by_weekday": [1, 3, 5], "by_monthday": [], "hour_from": 9, "hour_to": 17, "duration": 30, "priority": 5}], "invite_rules": [{"until": 0, "by_weekday": [], "by_monthday": [1, 15], "hour_from": 10, "hour_to": 12, "duration": 60, "priority": 8}], "attendees_required": [100, 101], "attendees_optional": [200]}'

	delete_call, delete_result := planning.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := planning.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := planning.example('list')
	assert list_call == '{}'
	assert list_result == '[{"name": "My Planning", "description": "A personal planning", "color": "#FF0000", "timezone": "UTC", "is_public": true, "calendar_template_id": 1, "registration_desk_id": 10, "autoschedule_rules": [{"until": 1893456000, "by_weekday": [1, 3, 5], "by_monthday": [], "hour_from": 9, "hour_to": 17, "duration": 30, "priority": 5}], "invite_rules": [{"until": 0, "by_weekday": [], "by_monthday": [1, 15], "hour_from": 10, "hour_to": 12, "duration": 60, "priority": 8}], "attendees_required": [100, 101], "attendees_optional": [200]}]'

	unknown_call, unknown_result := planning.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println('✓ Planning example test passed!')
}
