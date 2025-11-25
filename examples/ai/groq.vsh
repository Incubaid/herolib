#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.openai
import os
import incubaid.herolib.core.playcmds

// models see https://console.groq.com/docs/models

playcmds.run(
	heroscript: '
        !!openai.configure name:"groq"
            url:"https://api.groq.com/openai/v1"
            model_default:"openai/gpt-oss-120b"
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
