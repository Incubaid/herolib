module jina

import freeflowuniverse.herolib.core.httpconnection
import json

// JinaModel represents the available Jina models
pub enum JinaModel {
	jina_clip_v1
	jina_clip_v2
	jina_embeddings_v2_base_en
	jina_embeddings_v2_base_es
	jina_embeddings_v2_base_de
	jina_embeddings_v2_base_zh
	jina_embeddings_v2_base_code
	jina_embeddings_v3
}

// to_string converts a JinaModel enum to its string representation as expected by the Jina API
pub fn (m JinaModel) to_string() string {
	return match m {
		.jina_clip_v1 { 'jina-clip-v1' }
		.jina_clip_v2 { 'jina-clip-v2' }
		.jina_embeddings_v2_base_en { 'jina-embeddings-v2-base-en' }
		.jina_embeddings_v2_base_es { 'jina-embeddings-v2-base-es' }
		.jina_embeddings_v2_base_de { 'jina-embeddings-v2-base-de' }
		.jina_embeddings_v2_base_zh { 'jina-embeddings-v2-base-zh' }
		.jina_embeddings_v2_base_code { 'jina-embeddings-v2-base-code' }
		.jina_embeddings_v3 { 'jina-embeddings-v3' }
	}
}

// from_string converts a string to a JinaModel enum, returning an error if the string is invalid
pub fn jina_model_from_string(s string) !JinaModel {
	return match s {
		'jina-clip-v1' { JinaModel.jina_clip_v1 }
		'jina-clip-v2' { JinaModel.jina_clip_v2 }
		'jina-embeddings-v2-base-en' { JinaModel.jina_embeddings_v2_base_en }
		'jina-embeddings-v2-base-es' { JinaModel.jina_embeddings_v2_base_es }
		'jina-embeddings-v2-base-de' { JinaModel.jina_embeddings_v2_base_de }
		'jina-embeddings-v2-base-zh' { JinaModel.jina_embeddings_v2_base_zh }
		'jina-embeddings-v2-base-code' { JinaModel.jina_embeddings_v2_base_code }
		'jina-embeddings-v3' { JinaModel.jina_embeddings_v3 }
		else { return error('Invalid Jina model string: ${s}') }
	}
}

// TruncateType represents the available truncation options
pub enum TruncateType {
	none_ // "NONE"
	start // "START"
	end   // "END"
}

// to_string converts TruncateType enum to its string representation
pub fn (t TruncateType) to_string() string {
	return match t {
		.none_ { 'NONE' }
		.start { 'START' }
		.end { 'END' }
	}
}

// from_string converts string to TruncateType enum
pub fn truncate_type_from_string(s string) !TruncateType {
	return match s {
		'NONE' { TruncateType.none_ }
		'START' { TruncateType.start }
		'END' { TruncateType.end }
		else { return error('Invalid truncate type string: ${s}') }
	}
}

// EmbeddingType represents the available embedding types
pub enum EmbeddingType {
	float   // "float"
	base64  // "base64"
	binary  // "binary"
	ubinary // "ubinary"
}

// to_string converts EmbeddingType enum to its string representation
pub fn (t EmbeddingType) to_string() string {
	return match t {
		.float { 'float' }
		.base64 { 'base64' }
		.binary { 'binary' }
		.ubinary { 'ubinary' }
	}
}

// from_string converts string to EmbeddingType enum
pub fn embedding_type_from_string(s string) !EmbeddingType {
	return match s {
		'float' { EmbeddingType.float }
		'base64' { EmbeddingType.base64 }
		'binary' { EmbeddingType.binary }
		'ubinary' { EmbeddingType.ubinary }
		else { return error('Invalid embedding type string: ${s}') }
	}
}

// TaskType represents the available task types for embeddings
pub enum TaskType {
	retrieval_query   // "retrieval.query"
	retrieval_passage // "retrieval.passage"
	text_matching     // "text-matching"
	classification    // "classification"
	separation        // "separation"
}

// from_string converts string to TaskType enum
pub fn task_type_from_string(s string) !TaskType {
	return match s {
		'retrieval.query' { TaskType.retrieval_query }
		'retrieval.passage' { TaskType.retrieval_passage }
		'text-matching' { TaskType.text_matching }
		'classification' { TaskType.classification }
		'separation' { TaskType.separation }
		else { return error('Invalid task type string: ${s}') }
	}
}

// to_string converts TaskType enum to its string representation
pub fn (t TaskType) to_string() string {
	return match t {
		.retrieval_query { 'retrieval.query' }
		.retrieval_passage { 'retrieval.passage' }
		.text_matching { 'text-matching' }
		.classification { 'classification' }
		.separation { 'separation' }
	}
}

// Usage represents token usage information
pub struct Usage {
pub mut:
	total_tokens int
	unit         string
}

// TextEmbeddingInput represents the input for text embedding requests with enum types
pub struct TextEmbeddingInput {
pub mut:
	model         string = 'jina-embeddings-v2-base-en'
	input         []string @[required]
	task          TaskType       // task type
	type_         ?EmbeddingType // embedding type
	truncate      ?TruncateType  // truncation type
	late_chunking ?bool          // Flag to determine if late chunking is applied
}

// EmbeddingData represents a single embedding result
pub struct EmbeddingData {
pub mut:
	embedding []f64
	index     int
	object    string
}

// ModelEmbeddingOutput represents the response from embedding requests
pub struct ModelEmbeddingOutput {
pub mut:
	model     string
	data      []EmbeddingData
	usage     Usage
	object    string
	dimension int
}

// CreateEmbeddingParams represents the parameters for creating embeddings
@[params]
pub struct CreateEmbeddingParams {
pub mut:
	input         []string  @[required] // Input texts
	model         JinaModel @[required] // Model name
	task          string    @[required] // Task type
	type_         ?EmbeddingType // embedding type
	truncate      ?TruncateType  // truncation type
	late_chunking ?bool          // Flag to determine if late chunking is applied
}

// Create embeddings for input texts
pub fn (mut j Jina) create_embeddings(params CreateEmbeddingParams) !ModelEmbeddingOutput {
	task := task_type_from_string(params.task)!

	mut embedding_input := TextEmbeddingInput{
		input: params.input
		model: params.model.to_string()
		task:  task
	}

	if v := params.type_ {
		embedding_input.type_ = v
	}

	if v := params.truncate {
		embedding_input.truncate = v
	}

	embedding_input.late_chunking = if _ := params.late_chunking { true } else { false }

	req := httpconnection.Request{
		method:     .post
		prefix:     'v1/embeddings'
		dataformat: .json
		data:       json.encode(embedding_input)
	}

	mut httpclient := j.httpclient()!
	response := httpclient.post_json_str(req)!
	return json.decode(ModelEmbeddingOutput, response)!
}

pub struct HealthResponse {
pub mut:
	status  string
	message string
	healthy bool
}

pub fn (mut j Jina) health() !HealthResponse {
	req := httpconnection.Request{
		method: .get
	}

	mut httpclient := j.httpclient()!
	response := httpclient.send(req)!
	if response.code == 200 {
		return HealthResponse{
			status:  response.code.str()
			message: '200 Service available'
			healthy: true
		}
	}
	return HealthResponse{
		status:  response.code.str()
		message: '${response.code} Service Unavailable'
		healthy: false
	}
}
