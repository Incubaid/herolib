#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.mailclient

// remove the previous one, otherwise the env variables are not read
mailclient.config_delete(name: 'test')!

// env variables which need to be set are:
// - MAIL_FROM=...
// - MAIL_PASSWORD=...
// - MAIL_PORT=465
// - MAIL_SERVER=...
// - MAIL_USERNAME=...

mut client := mailclient.get(name: 'test')!

println(client)

client.send(
	subject: 'this is a test'
	to:      'kristof@incubaid.com'
	body:    '
    this is my email content
    '
)!
