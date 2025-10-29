#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.openai
import incubaid.herolib.core.playcmds

//to set the API key, either set it here, or set the OPENAI_API_KEY environment variable

playcmds.run(
	heroscript: '
		!!openai.configure name: "default" key: "" url: "https://openrouter.ai/api/v1" model_default: "gpt-oss-120b"
	'
)!

// name:'default' is the default, you can change it to whatever you want
mut client := openai.get()!

mut r := client.chat_completion(
	model:                 'gpt-oss-20b'
	message:               'Hello, world!'
	temperature:           0.3
	max_completion_tokens: 1024
)!
