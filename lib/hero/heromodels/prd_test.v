module heromodels

import incubaid.herolib.hero.db

fn test_prd_new() ! {
	mut mydb := db.new_test()!
	mut db_prd := DBPrd{
		db: &mydb
	}

	mut args := PrdArg{
		product_name: 'Test Product'
		version:      'v1.0'
		overview:     'This is a test product.'
		vision:       'To revolutionize testing.'
		goals:        []
		use_cases:    []
		requirements: []
		constraints:  []
	}

	prd := db_prd.new(args)!

	assert prd.product_name == 'Test Product'
	assert prd.version == 'v1.0'
	assert prd.overview == 'This is a test product.'
	assert prd.vision == 'To revolutionize testing.'
	assert prd.goals.len == 0
	assert prd.use_cases.len == 0
	assert prd.requirements.len == 0
	assert prd.constraints.len == 0
	assert prd.updated_at > 0

	println('✓ PRD new test passed!')
}

fn test_prd_crud_operations() ! {
	mut mydb := db.new_test()!
	mut db_prd := DBPrd{
		db: &mydb
	}

	// Create a new PRD
	mut args := PrdArg{
		product_name: 'CRUD Test Product'
		version:      'v1.0'
		overview:     'This is a test product for CRUD.'
		vision:       'To test CRUD operations.'
		goals:        []
		use_cases:    []
		requirements: []
		constraints:  []
	}

	mut prd := db_prd.new(args)!
	prd = db_prd.set(prd)!
	original_id := prd.id

	// Test get
	retrieved_prd := db_prd.get(original_id)!
	assert retrieved_prd.product_name == 'CRUD Test Product'
	assert retrieved_prd.version == 'v1.0'
	assert retrieved_prd.id == original_id

	// Test exist
	exists := db_prd.exist(original_id)!
	assert exists == true

	// Test delete
	db_prd.delete(original_id)!
	exists_after_delete := db_prd.exist(original_id)!
	assert exists_after_delete == false

	println('✓ PRD CRUD operations test passed!')
}

fn test_prd_encoding_decoding_complex() ! {
	mut mydb := db.new_test()!
	mut db_prd := DBPrd{
		db: &mydb
	}

	mut goal := Goal{
		id:          'G1'
		title:       'Speed'
		description: 'Generate PRDs in minutes'
		gtype:       .product
	}

	mut use_case := UseCase{
		id:      'UC1'
		title:   'Create PRD'
		actor:   'Product Manager'
		goal:    'Produce PRD quickly'
		steps:   ['Click new', 'Fill data', 'Export']
		success: 'Valid PRD generated'
		failure: 'Missing fields'
	}

	mut criterion := AcceptanceCriterion{
		id:          'AC1'
		description: 'System displays template list'
		condition:   'List contains >= 5 templates'
	}

	mut requirement := Requirement{
		id:           'R1'
		category:     'Editor'
		title:        'Template Selection'
		rtype:        .functional
		description:  'User can select from predefined templates'
		priority:     .high
		criteria:     [criterion]
		dependencies: []
	}

	mut constraint := Constraint{
		id:          'C1'
		title:       'ARM64 Only'
		description: 'Must run on ARM64 servers'
		ctype:       .technica
	}

	mut args := PrdArg{
		product_name: 'Complex Test Product'
		version:      'v2.0'
		overview:     'Complete test with all fields'
		vision:       'Full feature test'
		goals:        [goal]
		use_cases:    [use_case]
		requirements: [requirement]
		constraints:  [constraint]
	}

	mut prd := db_prd.new(args)!
	prd = db_prd.set(prd)!
	prd_id := prd.id

	// Retrieve and verify
	retrieved_prd := db_prd.get(prd_id)!

	assert retrieved_prd.product_name == 'Complex Test Product'
	assert retrieved_prd.goals.len == 1
	assert retrieved_prd.goals[0].id == 'G1'
	assert retrieved_prd.goals[0].gtype == .product

	assert retrieved_prd.use_cases.len == 1
	assert retrieved_prd.use_cases[0].id == 'UC1'
	assert retrieved_prd.use_cases[0].steps.len == 3

	assert retrieved_prd.requirements.len == 1
	assert retrieved_prd.requirements[0].id == 'R1'
	assert retrieved_prd.requirements[0].criteria.len == 1
	assert retrieved_prd.requirements[0].priority == .high

	assert retrieved_prd.constraints.len == 1
	assert retrieved_prd.constraints[0].id == 'C1'
	assert retrieved_prd.constraints[0].ctype == .technica

	println('✓ PRD encoding/decoding complex test passed!')
}

fn test_prd_type_name() ! {
	mut mydb := db.new_test()!
	mut db_prd := DBPrd{
		db: &mydb
	}

	mut args := PrdArg{
		product_name: 'Type Name Test'
		version:      'v1.0'
		overview:     'Test'
		vision:       'Test'
		goals:        []
		use_cases:    []
		requirements: []
		constraints:  []
	}

	prd := db_prd.new(args)!
	type_name := prd.type_name()
	assert type_name == 'prd'

	println('✓ PRD type_name test passed!')
}

fn test_prd_list() ! {
	mut mydb := db.new_test()!
	// Clear the test database to ensure clean state
	mydb.redis.flushdb()!

	mut db_prd := DBPrd{
		db: &mydb
	}
	// Clear any existing PRDs before running the test
	existing_prds := db_prd.list()!
	for prd_id in existing_prds {
		db_prd.delete[ProductRequirementsDoc](u32(prd_id))!
	}

	// Create multiple PRDs
	for i in 0 .. 3 {
		mut args := PrdArg{
			product_name: 'Product ${i}'
			version:      'v1.0'
			overview:     'Overview ${i}'
			vision:       'Vision ${i}'
			goals:        []
			use_cases:    []
			requirements: []
			constraints:  []
		}
		mut prd := db_prd.new(args)!
		prd = db_prd.set(prd)!
	}

	// List all PRDs
	all_prds := db_prd.list()!
	assert all_prds.len == 3

	println('✓ PRD list test passed!')
}
