module audio_test

import os
import clients.openai
import clients.openai.audio
import clients.openai.openai_factory_ { get }
import freeflowuniverse.crystallib.osal { play }

fn test_audio() {
	key := os.getenv('OPENAI_API_KEY')
	heroscript := '!!openai.configure api_key: "${key}"'

	play(heroscript: heroscript)!

	mut client := get()!

	// create speech
	client.create_speech(
		input:           'the quick brown fox jumps over the lazy dog'
		output_path:     '/tmp/output.mp3'
		voice:           audio.Voice.alloy
		response_format: audio.AudioFormat.mp3
	)!

	assert os.exists('/tmp/output.mp3')
}
