module openai

import os
import openai.audio
import openai.files
import openai.finetune
import openai.images

fn test_chat_completion() {
	mut client := get()!

	client.model_default = 'llama-3.3-70b-versatile'

	println(client.list_models()!)

	raise('sss')

	res := client.chat_completion(Messages{
		messages: [
			Message{
				role:    .user
				content: 'Say these words exactly as i write them with no punctuation: AI is getting out of hand'
			},
		]
	})!

	assert res.choices.len == 1

	assert res.choices[0].message.content == 'AI is getting out of hand'
}
