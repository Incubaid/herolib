module embeddings_test

import os
import clients.openai
import clients.openai.embeddings
import clients.openai.openai_factory_ { get }
import freeflowuniverse.crystallib.osal { play }

fn test_embeddings() {
	key := os.getenv('OPENAI_API_KEY')
	heroscript := '!!openai.configure api_key: "${key}"'

	play(heroscript: heroscript)!

	mut client := get()!

	res := client.create_embeddings(
		input: ['The food was delicious and the waiter..']
		model: embeddings.EmbeddingModel.text_embedding_ada
	)!

	assert res.data.len == 1
	assert res.data[0].embedding.len == 1536
}
