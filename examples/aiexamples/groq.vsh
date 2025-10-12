#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

module main

import incubaid.herolib.clients.openai
import os

fn test1(mut client openai.OpenAI) ! {
	instruction := '
	You are a template language converter. You convert Pug templates to Jet templates.

	The target template language, Jet, is defined as follows:
	'

	// Create a chat completion request
	res := client.chat_completion(
		msgs: openai.Messages{
			messages: [
				openai.Message{
					role:    .user
					content: 'What are the key differences between Groq and other AI inference providers?'
				},
			]
		}
	)!

	// Print the response
	println('\nGroq AI Response:')
	println('==================')
	println(res.choices[0].message.content)
	println('\nUsage Statistics:')
	println('Prompt tokens: ${res.usage.prompt_tokens}')
	println('Completion tokens: ${res.usage.completion_tokens}')
	println('Total tokens: ${res.usage.total_tokens}')
}

fn test2(mut client openai.OpenAI) ! {
	// Create a chat completion request
	res := client.chat_completion(
		model: 'deepseek-r1-distill-llama-70b'
		msgs:  openai.Messages{
			messages: [
				openai.Message{
					role:    .user
					content: 'A story of 10 lines?'
				},
			]
		}
	)!

	println('\nGroq AI Response:')
	println('==================')
	println(res.choices[0].message.content)
	println('\nUsage Statistics:')
	println('Prompt tokens: ${res.usage.prompt_tokens}')
	println('Completion tokens: ${res.usage.completion_tokens}')
	println('Total tokens: ${res.usage.total_tokens}')
}

println("
TO USE:
export AIKEY='gsk_...'
export AIURL='https://api.groq.com/openai/v1'
export AIMODEL='llama-3.3-70b-versatile'
")

mut client := openai.get(name: 'test')!
println(client)

// test1(mut client)!
test2(mut client)!
