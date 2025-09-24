# Quick Example: Transcribing Audio

```v

import freeflowuniverse.herolib.clients.openai

mut client:= openai.get()! //will be the default client, key is in `AIKEY` on environment variable or `OPENROUTER_API_KEY`

// Assuming you have an audio file named 'audio.mp3' in the same directory
// For a real application, handle file paths dynamically
audio_file_path := 'audio.mp3'

resp := client.audio.create_transcription(
    file: audio_file_path,
    model: 'whisper-1'
)!

```

