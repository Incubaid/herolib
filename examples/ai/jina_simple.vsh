#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.jina
import os
import json

mut j := jina.new()!

embeddings := j.create_embeddings(
	input: ['Hello world', 'This is a test']
	model: .jina_embeddings_v3
	task:  'separation'
) or {
	println('Error creating embeddings: ${err}')
	return
}

println('Embeddings created successfully!')
println('Model: ${embeddings.model}')
println('Dimension: ${embeddings.dimension}')
println('Number of embeddings: ${embeddings.data.len}')

// If there are embeddings, print the first one (truncated)
if embeddings.data.len > 0 {
	first_embedding := embeddings.data[0]
	println('First embedding (first 5 values): ${first_embedding.embedding[0..5]}')
}

// Usage information
println('Token usage: ${embeddings.usage.total_tokens} ${embeddings.usage.unit}')
