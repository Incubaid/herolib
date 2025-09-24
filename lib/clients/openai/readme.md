# openai

To get started

```v

import freeflowuniverse.herolib.clients.openai
import freeflowuniverse.herolib.core.playcmds

playcmds.run(
    heroscript:'
        !!openai.configure name:"default" 
            key:"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" 
            url:"https://openrouter.ai/api/v1" 
            model_default:"gpt-oss-120b"
        '
    reset: false
)!

//name:'default' is the default, you can change it to whatever you want
mut client:= openai.get()!

mut r:=client.chat_completion(
	model: "gpt-3.5-turbo",
	message: 'Hello, world!'
	temperature: 0.5
	max_completion_tokens: 1024
)!

```

if key empty then will try to get it from environment variable `AIKEY` or `OPENROUTER_API_KEY`
