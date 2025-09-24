
# Example: Uploading a File

```v
import freeflowuniverse.herolib.clients.openai

mut client:= openai.get()! //will be the default client, key is in `AIKEY` on environment variable or `OPENROUTER_API_KEY`

// Assuming you have a file named 'mydata.jsonl' in the same directory
// For a real application, handle file paths dynamically
file_path := 'mydata.jsonl'

resp := client.files.upload_file(
    file: file_path,
    purpose: 'fine-tune' // or 'assistants', 'batch', 'vision'
)

if resp.id.len > 0 {
    println('File uploaded successfully with ID: ${resp.id}')
} else {
    eprintln('Failed to upload file.')
}


```