#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

// Example demonstrating GraphDB usage in a social network context
import incubaid.herolib.data.graphdb

fn main() {
	// Initialize a new graph database with default cache settings
	mut gdb := graphdb.new(
		path:  '/tmp/social_network_example'
		reset: true // Start fresh each time
	)!

	println('=== Social Network Graph Example ===\n')

	// 1. Creating User Nodes
	println('Creating users...')
	mut alice_id := gdb.create_node({
		'type':       'user'
		'name':       'Alice Chen'
		'age':        '28'
		'location':   'San Francisco'
		'occupation': 'Software Engineer'
	})!
	println('Created user: ${gdb.debug_node(alice_id)!}')

	mut bob_id := gdb.create_node({
		'type':       'user'
		'name':       'Bob Smith'
		'age':        '32'
		'location':   'New York'
		'occupation': 'Product Manager'
	})!
	println('Created user: ${gdb.debug_node(bob_id)!}')

	mut carol_id := gdb.create_node({
		'type':       'user'
		'name':       'Carol Davis'
		'age':        '27'
		'location':   'San Francisco'
		'occupation': 'Data Scientist'
	})!
	println('Created user: ${gdb.debug_node(carol_id)!}')

	// 2. Creating Organization Nodes
	println('\nCreating organizations...')
	mut techcorp_id := gdb.create_node({
		'type':     'organization'
		'name':     'TechCorp'
		'industry': 'Technology'
		'location': 'San Francisco'
		'size':     '500+'
	})!
	println('Created organization: ${gdb.debug_node(techcorp_id)!}')

	mut datacorp_id := gdb.create_node({
		'type':     'organization'
		'name':     'DataCorp'
		'industry': 'Data Analytics'
		'location': 'New York'
		'size':     '100-500'
	})!
	println('Created organization: ${gdb.debug_node(datacorp_id)!}')

	// 3. Creating Interest Nodes
	println('\nCreating interest groups...')
	mut ai_group_id := gdb.create_node({
		'type':     'group'
		'name':     'AI Enthusiasts'
		'category': 'Technology'
		'members':  '0'
	})!
	println('Created group: ${gdb.debug_node(ai_group_id)!}')

	// 4. Establishing Relationships
	println('\nCreating relationships...')

	// Friendship relationships
	gdb.create_edge(alice_id, bob_id, 'FRIENDS', {
		'since':    '2022'
		'strength': 'close'
	})!
	gdb.create_edge(alice_id, carol_id, 'FRIENDS', {
		'since':    '2023'
		'strength': 'close'
	})!

	// Employment relationships
	gdb.create_edge(alice_id, techcorp_id, 'WORKS_AT', {
		'role':       'Senior Engineer'
		'since':      '2021'
		'department': 'Engineering'
	})!
	gdb.create_edge(bob_id, datacorp_id, 'WORKS_AT', {
		'role':       'Product Lead'
		'since':      '2020'
		'department': 'Product'
	})!
	gdb.create_edge(carol_id, techcorp_id, 'WORKS_AT', {
		'role':       'Data Scientist'
		'since':      '2022'
		'department': 'Analytics'
	})!

	// Group memberships
	gdb.create_edge(alice_id, ai_group_id, 'MEMBER_OF', {
		'joined': '2023'
		'status': 'active'
	})!
	gdb.create_edge(carol_id, ai_group_id, 'MEMBER_OF', {
		'joined': '2023'
		'status': 'active'
	})!

	// 5. Querying the Graph
	println('\nPerforming queries...')

	// Find users in San Francisco
	println('\nUsers in San Francisco:')
	sf_users := gdb.query_nodes_by_property('location', 'San Francisco')!
	for user in sf_users {
		if user.properties['type'] == 'user' {
			println('- ${user.properties['name']} (${user.properties['occupation']})')
		}
	}

	// Find Alice's friends
	println("\nAlice's friends:")
	alice_friends := gdb.get_connected_nodes(alice_id, 'FRIENDS', 'out')!
	for friend in alice_friends {
		println('- ${friend.properties['name']} in ${friend.properties['location']}')
	}

	// Find where Alice works
	println("\nAlice's workplace:")
	alice_workplaces := gdb.get_connected_nodes(alice_id, 'WORKS_AT', 'out')!
	for workplace in alice_workplaces {
		println('- ${workplace.properties['name']} (${workplace.properties['industry']})')
	}

	// Find TechCorp employees
	println('\nTechCorp employees:')
	techcorp_employees := gdb.get_connected_nodes(techcorp_id, 'WORKS_AT', 'in')!
	for employee in techcorp_employees {
		println('- ${employee.properties['name']} as ${employee.properties['occupation']}')
	}

	// Find AI group members
	println('\nAI Enthusiasts group members:')
	ai_members := gdb.get_connected_nodes(ai_group_id, 'MEMBER_OF', 'in')!
	for member in ai_members {
		println('- ${member.properties['name']}')
	}

	// 6. Updating Data
	println('\nUpdating data...')

	// Promote Alice
	println('\nPromoting Alice...')
	mut alice := gdb.get_node(alice_id)!
	alice.properties['occupation'] = 'Lead Software Engineer'
	gdb.update_node(alice_id, alice.properties)!

	// Update Alice's work relationship
	mut edges := gdb.get_edges_between(alice_id, techcorp_id)!
	if edges.len > 0 {
		gdb.update_edge(edges[0].id, {
			'role':       'Engineering Team Lead'
			'since':      '2021'
			'department': 'Engineering'
		})!
	}

	println('\nFinal graph structure:')
	gdb.print_graph()!
}
