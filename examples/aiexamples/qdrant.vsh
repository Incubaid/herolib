#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.qdrant
import incubaid.herolib.installers.db.qdrant_installer
import incubaid.herolib.core.httpconnection
import rand
import os

println('Starting Qdrant example script')

// Print environment information
println('Current directory: ${os.getwd()}')
println('Home directory: ${os.home_dir()}')

mut i := qdrant_installer.get()!
i.install()!

// 1. Get the qdrant client
println('Getting Qdrant client...')
mut qdrant_client := qdrant.get()!
println('Qdrant client URL: ${qdrant_client.url}')

// Check if Qdrant server is running
println('Checking Qdrant server health...')
health := qdrant_client.health_check() or {
	println('Error checking health: ${err}')
	false
}
println('Qdrant server health: ${health}')

// Get service info
println('Getting Qdrant service info...')
service_info := qdrant_client.get_service_info() or {
	println('Error getting service info: ${err}')
	exit(1)
}
println('Qdrant service info: ${service_info}')

// 2. Generate collection name
collection_name := 'collection_' + rand.string(4)
println('Generated collection name: ${collection_name}')

// 3. Create a new collection
println('Creating collection...')
created_collection := qdrant_client.create_collection(
	collection_name: collection_name
	size:            15
	distance:        'Cosine'
) or {
	println('Error creating collection: ${err}')
	exit(1)
}
println('Created Collection: ${created_collection}')

// 4. Get the created collection
println('Getting collection...')
get_collection := qdrant_client.get_collection(
	collection_name: collection_name
) or {
	println('Error getting collection: ${err}')
	exit(1)
}
println('Get Collection: ${get_collection}')

// 5. List all collections
println('Listing collections...')
list_collection := qdrant_client.list_collections() or {
	println('Error listing collections: ${err}')
	exit(1)
}
println('List Collection: ${list_collection}')

// 6. Check collection existence
println('Checking collection existence...')
collection_existence := qdrant_client.is_collection_exists(
	collection_name: collection_name
) or {
	println('Error checking collection existence: ${err}')
	exit(1)
}
println('Collection Existence: ${collection_existence}')

// 7. Retrieve points
println('Retrieving points...')
collection_points := qdrant_client.retrieve_points(
	collection_name: collection_name
	ids:             [
		0,
		3,
		100,
	]
) or {
	println('Error retrieving points: ${err}')
	exit(1)
}
println('Collection Points: ${collection_points}')

// 8. Upsert points
println('Upserting points...')
upsert_points := qdrant_client.upsert_points(
	collection_name: collection_name
	points:          [
		qdrant.Point{
			payload: {
				'key': 'value'
			}
			vector:  [1.0, 2.0, 3.0]
		},
		qdrant.Point{
			payload: {
				'key': 'value'
			}
			vector:  [4.0, 5.0, 6.0]
		},
		qdrant.Point{
			payload: {
				'key': 'value'
			}
			vector:  [7.0, 8.0, 9.0]
		},
	]
) or {
	println('Error upserting points: ${err}')
	exit(1)
}
println('Upsert Points: ${upsert_points}')

println('Qdrant example script completed successfully')
