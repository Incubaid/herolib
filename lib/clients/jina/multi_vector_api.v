module jina

import json
import incubaid.herolib.core.httpconnection

// Enum for available Jina multi-vector models
pub enum MultiVectorModel {
	jina_colbert_v1_en // jina-colbert-v1-en (may have server-side issues)
	jina_colbert_v2    // jina-colbert-v2 (recommended)
}

// Convert the enum to a valid string
pub fn (m MultiVectorModel) to_string() string {
	return match m {
		.jina_colbert_v1_en { 'jina-colbert-v1-en' }
		.jina_colbert_v2 { 'jina-colbert-v2' }
	}
}

// Enum for input types
pub enum MultiVectorInputType {
	document // document
	query    // query
}

// to_string converts MultiVectorInputType to its string representation
pub fn (t MultiVectorInputType) to_string() string {
	return match t {
		.document { 'document' }
		.query { 'query' }
	}
}

// MultiVectorRequest represents the JSON request body for the /v1/multi-vector endpoint
struct MultiVectorRequest {
mut:
	model          string    @[required]               // Model name
	input          []string  @[required]               // Input texts (simple array of strings)
	input_type     ?string   @[json: 'input_type']     // Optional: Type of embedding (query or document)
	embedding_type ?[]string @[json: 'embedding_type'] // Optional: Embedding type
	dimensions     ?int // Optional: Number of dimensions
}

// MultiVectorResponse represents the JSON response body for the /v1/multi-vector endpoint
pub struct MultiVectorResponse {
pub:
	data   []MultiVectorEmbedding // List of multi-vector embeddings
	usage  Usage                  // Usage information
	model  string                 // Model name
	object string                 // Object type as string
}

// MultiVectorEmbedding represents a multi-vector embedding in the response
// Multi-vector embeddings are 2D arrays where each token has its own embedding vector
pub struct MultiVectorEmbedding {
pub:
	index      int     // Index of the document
	embeddings [][]f64 // 2D array of embeddings (one vector per token)
	object     string  // Object type as string
}

// MultiVectorParams represents the parameters for a multi-vector request
@[params]
pub struct MultiVectorParams {
pub mut:
	model          MultiVectorModel = .jina_colbert_v2 // Model name (default to v2 which is more stable)
	input          []string              // Input texts (simple array of strings)
	input_type     ?MultiVectorInputType // Optional: Type of the embedding to compute, query or document
	embedding_type ?[]string             // Optional: Embedding type
	dimensions     ?int                  // Optional: Number of dimensions
}

// CreateMultiVector creates a multi-vector request and returns the response
pub fn (mut j Jina) create_multi_vector(params MultiVectorParams) !MultiVectorResponse {
	mut request := MultiVectorRequest{
		model:          params.model.to_string()
		input:          params.input
		embedding_type: params.embedding_type
		dimensions:     params.dimensions
	}

	// Set input_type if provided
	if input_type := params.input_type {
		request.input_type = input_type.to_string()
	}

	req := httpconnection.Request{
		method:     .post
		prefix:     'v1/multi-vector'
		dataformat: .json
		data:       json.encode(request)
	}

	mut httpclient := j.httpclient()!
	response := httpclient.post_json_str(req)!
	result := json.decode(MultiVectorResponse, response)!
	return result
}
