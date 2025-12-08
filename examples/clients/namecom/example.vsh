#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook
import incubaid.herolib.clients.namecomclient

// Initialize herolib
base.init()!

// Define heroscript - replace with your actual credentials and domain
heroscript := "
!!namecomclient.configure
    url: 'https://api.name.com'
    username: 'YOUR_USERNAME'
    token: 'YOUR_API_TOKEN'

// List all domains in account
!!namecomclient.domains_list

// Set an A record for a subdomain
// !!namecomclient.record_set
//     domain: 'yourdomain.com'
//     host: 'test'
//     type: 'A'
//     answer: '10.0.0.1'
//     ttl: 300
"

mut plbook := playbook.new(text: heroscript)!
namecomclient.play(mut plbook)!

println('Done!')
