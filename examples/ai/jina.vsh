#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.jina

mut jina_client := jina.new()!
health := jina_client.health()!
println('Server health: ${health}')

// Create embeddings
embeddings := jina_client.create_embeddings(
	input: ['Hello', 'World']
	model: .jina_embeddings_v3
	task:  'separation'
) or { panic('Error while creating embeddings: ${err}') }

println('Created embeddings: ${embeddings}')

// Rerank
rerank_result := jina_client.rerank(
	model:     .reranker_v2_base_multilingual
	query:     'skincare products'
	documents: ['Product A', 'Product B', 'Product C']
	top_n:     2
) or { panic('Error while reranking: ${err}') }

println('Rerank result: ${rerank_result}')

// Train - using jina-embeddings-v2-base-en model (jina-clip-v1/v2 may have server-side issues)
train_result := jina_client.train(
	model: .jina_embeddings_v2_base_en
	input: [
		jina.TrainingExample{
			text:  'A photo of a cat'
			label: 'cat'
		},
		jina.TrainingExample{
			text:  'A photo of a dog'
			label: 'dog'
		},
	]
) or { panic('Error while training: ${err}') }

println('Train result: ${train_result}')

// Classify - using text inputs with embeddings model (jina-clip-v1/v2 may have server-side issues)
classify_result := jina_client.classify(
	model:  .jina_embeddings_v2_base_en
	input:  [
		jina.ClassificationInput{
			text: 'A photo of a cat'
		},
		jina.ClassificationInput{
			text: 'A photo of a dog'
		},
	]
	labels: ['cat', 'dog']
) or { panic('Error while classifying: ${err}') }

println('Classification result: ${classify_result}')

// List classifiers
classifiers := jina_client.list_classifiers() or { panic('Error fetching classifiers: ${err}') }
println('Classifiers: ${classifiers}')

// Delete classifier
delete_result := jina_client.delete_classifier(classifier_id: classifiers[0].classifier_id) or {
	panic('Error deleting classifier: ${err}')
}
println('Delete result: ${delete_result}')

// Create multi vector - using jina-colbert-v2 model (v1 has server-side issues)
multi_vector := jina_client.create_multi_vector(
	model:      .jina_colbert_v2
	input:      ['Hello world', "What's up?"]
	input_type: .document
)!
println('Multi vector: ${multi_vector}')
