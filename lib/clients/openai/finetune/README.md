# OpenAI Fine-tuning Client


```v
import freeflowuniverse.herolib.clients.openai

mut client:= openai.get()! //will be the default client, key is in `AIKEY` on environment variable or `OPENROUTER_API_KEY`

// Assuming you have a training file ID from the Files API
training_file_id := 'file-xxxxxxxxxxxxxxxxxxxxxxxxx'

resp := client.finetune.create_fine_tune(
    training_file: training_file_id,
    model: 'gpt-3.5-turbo'
)

if resp.id.len > 0 {
    println('Fine-tuning job created with ID: ${resp.id}')
} else {
    eprintln('Failed to create fine-tuning job.')
}
```