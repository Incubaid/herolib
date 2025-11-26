#!/usr/bin/env -S v -n -w -enable-globals run

import incubaid.herolib.clients.herodb

// Initialize the client
mut client := herodb.new(herodb.Config{
    url: 'http://localhost:3000'
})!

println('Connecting to HeroDB at ${client.server_url}...')

// List instances
instances := client.list_instances()!

println('Found ${instances.len} instances:')

for instance in instances {
    println('----------------------------------------')
    println('Index:       ${instance.index}')
    println('Name:        ${instance.name}')
    println('Created At:  ${instance.created_at}')
    
    // Parse backend info
    backend := instance.get_backend_info() or {
        println('Backend:     Unknown/Error (${err})')
        continue
    }
    
    println('Backend Type: ${backend.type_name}')
    if backend.path != '' {
        println('Backend Path: ${backend.path}')
    }
}
println('----------------------------------------')