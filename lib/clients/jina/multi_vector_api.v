module jina

import json
import incubaid.herolib.core.httpconnection

// Enum for available Jina multi-vector models
pub enum MultiVectorModel {
	jina_colbert_v1_en // jina-colbert-v1-en
}

// Convert the enum to a valid string
pub fn (m MultiVectorModel) to_string() string {
	return match m {
		.jina_colbert_v1_en { 'jina-colbert-v1-en' }
	}
}

// Enum for input types
pub enum MultiVectorInputType {
	document // document
	query    // query
}

// MultiVectorTextDoc represents a text document for a multi-vector request
pub struct MultiVectorTextDoc {
pub mut:
	id         ?string // Optional: ID of the document
	text       string @[required] // Text of the document
	input_type ?MultiVectorInputType // Optional: Type of the embedding to compute, query or document
}

// MultiVectorRequest represents the JSON request body for the /v1/multi-vector endpoint
struct MultiVectorRequest {
	model          string               // Model name
	input          []MultiVectorTextDoc // Input documents
	embedding_type ?[]string            // Optional: Embedding type
	dimensions     ?int                 // Optional: Number of dimensions
}

// MultiVectorResponse represents the JSON response body for the /v1/multi-vector endpoint
pub struct MultiVectorResponse {
	data   []Embedding // List of embeddings
	usage  Usage       // Usage information
	model  string      // Model name
	object string      // Object type as string
}

// EmbeddingObjType represents the embeddings object in the response
pub struct EmbeddingObjType {
pub mut:
	float  ?[][]f64  // Optional 2D array of floats for multi-vector embeddings
	base64 ?[]string // Optional array of base64 strings
	binary ?[]u8     // Optional array of bytes
}

// SEmbeddingType is a sum type to handle different embedding formats
pub type SEmbeddingType = EmbeddingObjType | []f64 | []string | []u8

// Embedding represents an embedding vector
pub struct Embedding {
	index      int            // Index of the document
	embeddings SEmbeddingType // Embedding vector as a sum type
	object     string         // Object type as string
}

// MultiVectorParams represents the parameters for a multi-vector request
@[params]
pub struct MultiVectorParams {
pub mut:
	model          MultiVectorModel = .jina_colbert_v1_en // Model name
	input          []MultiVectorTextDoc  // Input documents
	input_type     ?MultiVectorInputType // Optional: Type of the embedding to compute, query or document
	embedding_type ?[]string             // Optional: Embedding type
	dimensions     ?int                  // Optional: Number of dimensions
}

// CreateMultiVector creates a multi-vector request and returns the response
pub fn (mut j Jina) create_multi_vector(params MultiVectorParams) !MultiVectorResponse {
	request := MultiVectorRequest{
		model:          params.model.to_string()
		input:          params.input
		embedding_type: params.embedding_type
		dimensions:     params.dimensions
	}

	req := httpconnection.Request{
		method:     .post
		prefix:     'v1/multi-vector'
		dataformat: .json
		data:       json.encode(request)
	}

	mut httpclient := j.httpclient()!
	response := httpclient.post_json_str(req)!
	println('response: ${response}')
	result := json.decode(MultiVectorResponse, response)!
	return result
}
