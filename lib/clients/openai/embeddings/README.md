
# Quick Example: Creating Embeddings

```v

import freeflowuniverse.herolib.clients.openai

mut client:= openai.get()! //will be the default client, key is in `AIKEY` on environment variable or `OPENROUTER_API_KEY`

text_to_embed := 'The quick brown fox jumps over the lazy dog.'

resp := client.embeddings.create_embedding(
    input: text_to_embed,
    model: 'text-embedding-ada-002'
)!

```