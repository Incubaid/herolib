module jina

import time

fn setup_client() !&Jina {
	// Use new() to create a fresh client instance with API key from environment
	mut client := new()!
	return client
}

fn test_create_embeddings() {
	time.sleep(1 * time.second)
	mut client := setup_client()!
	embeddings := client.create_embeddings(
		input: ['Hello', 'World']
		model: .jina_embeddings_v3
		task:  'separation'
	) or { panic('Error while creating embeddings: ${err}') }

	assert embeddings.data.len > 0
	assert embeddings.object == 'list' // Check the object type
	assert embeddings.model == 'jina-embeddings-v3'
}

fn test_rerank() {
	time.sleep(1 * time.second)
	mut client := setup_client()!
	rerank_result := client.rerank(
		model:     .reranker_v2_base_multilingual
		query:     'skincare products'
		documents: ['Product A', 'Product B', 'Product C']
		top_n:     2
	) or { panic('Error while reranking: ${err}') }

	assert rerank_result.results.len == 2
	assert rerank_result.model == 'jina-reranker-v2-base-multilingual'
}

fn test_train() {
	time.sleep(1 * time.second)
	mut client := setup_client()!
	// Using jina-embeddings-v2-base-en as jina-clip-v1/v2 may have server-side issues
	train_result := client.train(
		model: .jina_embeddings_v2_base_en
		input: [
			TrainingExample{
				text:  'A photo of a cat'
				label: 'cat'
			},
			TrainingExample{
				text:  'A photo of a dog'
				label: 'dog'
			},
		]
	) or { panic('Error while training: ${err}') }

	assert train_result.classifier_id.len > 0
	assert train_result.num_samples == 2
}

fn test_classify() {
	time.sleep(1 * time.second)
	mut client := setup_client()!
	// Using jina-embeddings-v2-base-en (text-only model) - jina-clip-v1/v2 may have server-side issues
	// Note: This model only supports text input, not images
	classify_result := client.classify(
		model:  .jina_embeddings_v2_base_en
		input:  [
			ClassificationInput{
				text: 'A photo of a cat'
			},
			ClassificationInput{
				text: 'A photo of a dog running in a park'
			},
		]
		labels: ['cat', 'dog']
	) or { panic('Error while classifying: ${err}') }

	assert classify_result.data.len == 2
	assert classify_result.data[0].prediction in ['cat', 'dog']
	assert classify_result.data[1].prediction in ['cat', 'dog']
	assert classify_result.data[0].object == 'classification'
	assert classify_result.data[1].object == 'classification'
}

fn test_get_classifiers() {
	time.sleep(1 * time.second)
	mut client := setup_client()!
	classifiers := client.list_classifiers() or { panic('Error fetching classifiers: ${err}') }
	assert classifiers.len != 0
}

// Delete classifier
fn test_delete_classifiers() {
	time.sleep(1 * time.second)
	mut client := setup_client()!

	classifiers := client.list_classifiers() or { panic('Error fetching classifiers: ${err}') }
	assert classifiers.len != 0

	delete_result := client.delete_classifier(classifier_id: classifiers[0].classifier_id) or {
		panic('Error deleting classifier: ${err}')
	}

	assert delete_result == '{"message":"Classifier ${classifiers[0].classifier_id} deleted"}'
}
