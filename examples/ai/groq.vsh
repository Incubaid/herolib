#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

module main

import incubaid.herolib.clients.openai
import os
import incubaid.herolib.core.playcmds


playcmds.run(
	heroscript: '
        !!openai.configure name:"qroq" 
            url:"https://api.groq.com/openai/v1" 
            model_default:"gpt-oss-120b"
    '
	reset:      true
)!

mut client := openai.get(name: 'groq')!

response := client.chat_completion(
	message:               'Explain quantum computing in simple terms'
	temperature:           0.5
	max_completion_tokens: 1024
)!

println(response.result)

