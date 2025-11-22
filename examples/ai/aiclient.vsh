#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.ai.client

mut cl := client.new()!

// response := cl.llms.llm_local.chat_completion(
// 	message:               'Explain quantum computing in simple terms'
// 	temperature:           0.5
// 	max_completion_tokens: 1024
// )!

response := cl.llms.llm_embed_local.embed(input: [
	'The food was delicious and the waiter..',
])!

println(response)
