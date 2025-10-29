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

// Train
train_result := jina_client.train(
	model: .jina_clip_v1
	input: [
		jina.TrainingExample{
			text:  'Sample text'
			label: 'positive'
		},
		jina.TrainingExample{
			image: 'https://picsum.photos/id/11/367/267'
			label: 'negative'
		},
	]
) or { panic('Error while training: ${err}') }

println('Train result: ${train_result}')

// Classify
classify_result := jina_client.classify(
	model:  .jina_clip_v1
	input:  [
		jina.ClassificationInput{
			text: 'A photo of a cat'
		},
		jina.ClassificationInput{
			image: 'https://picsum.photos/id/11/367/267'
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

// Create multi vector
multi_vector := jina_client.create_multi_vector(
	input:          [
		jina.MultiVectorTextDoc{
			text:       'Hello world'
			input_type: .document
		},
		jina.MultiVectorTextDoc{
			text:       "What's up?"
			input_type: .query
		},
	]
	embedding_type: ['float']
	// dimensions:     96
)!
println('Multi vector: ${multi_vector}')
