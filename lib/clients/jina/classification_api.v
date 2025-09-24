module jina

import json
import freeflowuniverse.herolib.core.httpconnection

// ClassificationTrainAccess represents the accessibility of the classifier
pub enum ClassificationTrainAccess {
	public  // Classifier is publicly accessible
	private // Classifier is private (default)
}

// TrainingExample represents a single training example (either text or image with a label)
pub struct TrainingExample {
pub mut:
	text  ?string // Optional text content
	image ?string // Optional image URL
	label string  // Required label
}

// ClassificationTrainOutput represents the response from the training endpoint
pub struct ClassificationTrainOutput {
pub mut:
	classifier_id string                   // Identifier of the trained classifier
	num_samples   int                      // Number of samples used in training
	usage         ClassificationTrainUsage // Token usage details
}

// ClassificationTrainUsage represents token usage for the training request
pub struct ClassificationTrainUsage {
pub mut:
	total_tokens int // Total tokens consumed
}

// ClassificationTrain represents parameters for the training request
@[params]
pub struct ClassificationTrain {
pub mut:
	model         ?JinaModel // Optional model identifier (e.g., jina-clip-v1)
	classifier_id ?string    // Optional existing classifier ID
	access        ?ClassificationTrainAccess = .private // Accessibility, defaults to private
	input         []TrainingExample // Array of training examples
	num_iters     ?int = 10 // Number of training iterations, defaults to 10
}

// TrainRequest represents the JSON request body for the /v1/train endpoint
struct TrainRequest {
mut:
	model         ?string
	classifier_id ?string
	access        ?string
	input         []TrainingExample
	num_iters     ?int
}

// Train a classifier by sending a POST request to /v1/train
pub fn (mut j Jina) train(params ClassificationTrain) !ClassificationTrainOutput {
	// Validate that only one of model or classifier_id is provided
	mut model_provided := false
	mut classifier_id_provided := false
	if _ := params.model {
		model_provided = true
	}

	if _ := params.classifier_id {
		classifier_id_provided = true
	}

	if model_provided && classifier_id_provided {
		return error('Provide either model or classifier_id, not both')
	}

	if model := params.model {
		if model == .jina_embeddings_v3 {
			return error('jina-embeddings-v3 is not a valid model for classification')
		}
	}

	// Validate each training example has exactly one of text or image
	for example in params.input {
		mut text_provided := false
		mut image_provided := false

		if _ := example.text {
			text_provided = true
		}

		if _ := example.image {
			image_provided = true
		}

		if text_provided && image_provided {
			return error('Each training example must have either text or image, not both')
		}

		if !text_provided && !image_provided {
			return error('Each training example must have either text or image')
		}
	}

	// Construct the request body
	mut request := TrainRequest{
		input: params.input
	}
	if v := params.model {
		request.model = v.to_string() // Convert JinaModel enum to string
	}
	if v := params.classifier_id {
		request.classifier_id = v
	}
	if v := params.access {
		request.access = match v {
			.public { 'public' }
			.private { 'private' }
		}
	}
	if v := params.num_iters {
		request.num_iters = v
	}

	// Create and send the HTTP request
	req := httpconnection.Request{
		method:     .post
		prefix:     'v1/train'
		dataformat: .json
		data:       json.encode(request)
	}

	mut httpclient := j.httpclient()!
	response := httpclient.post_json_str(req)!
	result := json.decode(ClassificationTrainOutput, response)!
	return result
}

// TextDoc represents a text document for classification
pub struct TextDoc {
pub mut:
	text string // The text content
}

// ImageDoc represents an image document for classification
pub struct ImageDoc {
pub mut:
	image string // The image URL or base64-encoded string
}

// ClassificationInput represents a single input for classification (text or image)
pub struct ClassificationInput {
pub mut:
	text  ?string // Optional text content
	image ?string // Optional image content
}

// ClassificationOutput represents the response from the classify endpoint
pub struct ClassificationOutput {
pub mut:
	data  []ClassificationResult // List of classification results
	usage ClassificationUsage    // Token usage details
}

// ClassificationResult represents a single classification result
pub struct ClassificationResult {
pub mut:
	index       int          // Index of the input
	prediction  string       // Predicted label
	score       f64          // Confidence score
	object      string       // Type of object (e.g., "classification")
	predictions []LabelScore // List of label scores
}

// LabelScore represents a label and its corresponding score
pub struct LabelScore {
pub mut:
	label string // Label name
	score f64    // Confidence score
}

// ClassificationUsage represents token usage for the classification request
pub struct ClassificationUsage {
pub mut:
	total_tokens int // Total tokens consumed
}

// ClassifyRequest represents the JSON request body for the /v1/classify endpoint
struct ClassifyRequest {
mut:
	model         ?string
	classifier_id ?string
	input         []ClassificationInput
	labels        []string
}

// ClassifyParams represents parameters for the classification request
@[params]
pub struct ClassifyParams {
pub mut:
	model         ?JinaModel            // Optional model identifier
	classifier_id ?string               // Optional classifier ID
	input         []ClassificationInput // Array of inputs (text or image)
	labels        []string              // List of labels for classification
}

// Classify inputs by sending a POST request to /v1/classify
pub fn (mut j Jina) classify(params ClassifyParams) !ClassificationOutput {
	// Validate that only one of model or classifier_id is provided
	mut model_provided := false
	mut classifier_id_provided := false
	if _ := params.model {
		model_provided = true
	}
	if _ := params.classifier_id {
		classifier_id_provided = true
	}
	if model_provided && classifier_id_provided {
		return error('Provide either model or classifier_id, not both')
	}
	if !model_provided && !classifier_id_provided {
		return error('Either model or classifier_id must be provided')
	}

	// Validate each input has exactly one of text or image
	for input in params.input {
		mut text_provided := false
		mut image_provided := false
		if _ := input.text {
			text_provided = true
		}
		if _ := input.image {
			image_provided = true
		}
		if text_provided && image_provided {
			return error('Each input must have either text or image, not both')
		}
		if !text_provided && !image_provided {
			return error('Each input must have either text or image')
		}
	}

	// Construct the request body
	mut request := ClassifyRequest{
		input:  params.input
		labels: params.labels
	}
	if v := params.model {
		request.model = v.to_string() // Convert JinaModel enum to string
	}
	if v := params.classifier_id {
		request.classifier_id = v
	}

	// Create and send the HTTP request
	req := httpconnection.Request{
		method:     .post
		prefix:     'v1/classify'
		dataformat: .json
		data:       json.encode(request)
	}

	mut httpclient := j.httpclient()!
	response := httpclient.post_json_str(req)!
	result := json.decode(ClassificationOutput, response)!
	return result
}

// Define the Classifier struct
pub struct Classifier {
pub mut:
	classifier_id  string
	model_name     string
	labels         []string
	access         string
	updated_number int
	used_number    int
	created_at     string
	updated_at     string
	used_at        ?string
	metadata       map[string]string
}

// Implement the list_classifiers function
pub fn (mut j Jina) list_classifiers() ![]Classifier {
	req := httpconnection.Request{
		method: .get
		prefix: 'v1/classifiers'
	}
	mut httpclient := j.httpclient()!
	response := httpclient.get(req)!
	classifiers := json.decode([]Classifier, response)!
	return classifiers
}

// ClassifyParams represents parameters for the classification request
@[params]
pub struct DeleteClassifierParams {
pub mut:
	classifier_id string @[required] // The ID of the classifier to delete
}

// Function to delete a classifier by its ID
pub fn (mut j Jina) delete_classifier(params DeleteClassifierParams) !string {
	req := httpconnection.Request{
		method: .delete
		prefix: 'v1/classifiers/${params.classifier_id}'
	}

	mut httpclient := j.httpclient()!
	response := httpclient.delete(req)!
	return response
}
