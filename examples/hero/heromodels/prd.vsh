#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.hero.heromodels

// Initialize database
mut mydb := heromodels.new()!

// Create goals
mut goals := [
	heromodels.Goal{
		id:          'G1'
		title:       'Faster Requirements'
		description: 'Reduce PRD creation time to under 1 day'
		gtype:       .product
	},
]

// Create use cases
mut use_cases := [
	heromodels.UseCase{
		id:      'UC1'
		title:   'Generate PRD'
		actor:   'Product Manager'
		goal:    'Create validated PRD'
		steps:   ['Select template', 'Fill fields', 'Export to Markdown']
		success: 'Complete PRD generated'
		failure: 'Validation failed'
	},
]

// Create requirements
mut criterion := heromodels.AcceptanceCriterion{
	id:          'AC1'
	description: 'Display template list'
	condition:   'List contains >= 5 templates'
}

mut requirements := [
	heromodels.Requirement{
		id:           'R1'
		category:     'Editor'
		title:        'Template Selection'
		rtype:        .functional
		description:  'User can select from templates'
		priority:     .high
		criteria:     [criterion]
		dependencies: []
	},
]

// Create constraints
mut constraints := [
	heromodels.Constraint{
		id:          'C1'
		title:       'ARM64 Support'
		description: 'Must run on ARM64 infrastructure'
		ctype:       .technica
	},
]

// Create risks
mut risks := map[string]string{}
risks['RISK1'] = 'Templates too limited → Add community contributions'
risks['RISK2'] = 'AI suggestions inaccurate → Add review workflow'

// Create a new PRD object
mut prd := mydb.prd.new(
	product_name: 'Lumina PRD Builder'
	version:      'v1.0'
	overview:     'Tool to create structured PRDs quickly'
	vision:       'Enable teams to generate clear requirements in minutes'
	goals:        goals
	use_cases:    use_cases
	requirements: requirements
	constraints:  constraints
	risks:        risks
)!

// Save to database
prd = mydb.prd.set(prd)!
println('✓ Created PRD with ID: ${prd.id}')

// Retrieve from database
mut retrieved := mydb.prd.get(prd.id)!
println('✓ Retrieved PRD: ${retrieved.product_name}')

// List all PRDs
mut all_prds := mydb.prd.list()!
println('✓ Total PRDs in database: ${all_prds.len}')

// Check if exists
exists := mydb.prd.exist(prd.id)!
println('✓ PRD exists: ${exists}')
