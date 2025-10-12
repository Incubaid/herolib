#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.jina
import os
import json

fn main() {
	// Initialize Jina client
	mut j := jina.Jina{
		name:   'test_client'
		secret: os.getenv('JINAKEY')
	}

	// Initialize the client
	j = jina.obj_init(j) or {
		println('Error initializing Jina client: ${err}')
		return
	}

	// Check if authentication works
	auth_ok := j.check_auth() or {
		println('Authentication failed: ${err}')
		return
	}

	println('Authentication successful: ${auth_ok}')

	// Create embeddings
	model := 'jina-embeddings-v2-base-en'
	input := ['Hello world', 'This is a test']

	embeddings := j.create_embeddings(input, model, 'search') or {
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
}
