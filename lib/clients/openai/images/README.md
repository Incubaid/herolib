
#  Example: Creating an Image

```v

import freeflowuniverse.herolib.clients.openai

mut client:= openai.get()! //will be the default client, key is in `AIKEY` on environment variable or `OPENROUTER_API_KEY`

resp := client.images.create_image(
    prompt: 'A futuristic city at sunset',
    n: 1,
    size: '1024x1024'
)

if resp.data.len > 0 {
    println('Image created. URL: ${resp.data[0].url}')
} else {
    eprintln('Failed to create image.')
}
```
