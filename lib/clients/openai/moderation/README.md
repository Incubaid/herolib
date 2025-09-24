# OpenAI Moderation Client

This directory contains the V client for OpenAI's Moderation API.


```v

import freeflowuniverse.herolib.clients.openai

mut client:= openai.get()! //will be the default client, key is in `AIKEY` on environment variable or `OPENROUTER_API_KEY`

text_to_moderate := 'I want to kill them all.'

resp := client.moderation.create_moderation(
    input: text_to_moderate
)

if resp.results.len > 0 {
    if resp.results[0].flagged {
        println('Text was flagged for moderation.')
        println('Categories: ${resp.results[0].categories}')
    } else {
        println('Text passed moderation.')
    }
} else {
    eprintln('Failed to get moderation result.')
}

```

