module jina

import freeflowuniverse.herolib.core.httpconnection
import json

pub enum JinaRerankModel {
	reranker_v2_base_multilingual // 278M
	reranker_v1_base_en           // 137M
	reranker_v1_tiny_en           // 33M
	reranker_v1_turbo_en          // 38M
	colbert_v1_en                 // 137M
}

// RankAPIInput represents the input for reranking requests
pub struct RerankInput {
pub mut:
	model            string   @[required] // Model name
	query            string   @[required] // Query text
	documents        []string @[required] // Document texts
	top_n            ?int  // Optional: Number of top results to return
	return_documents ?bool // Optional: Flag to determine if the documents should be returned
}

// RankingOutput represents the response from reranking requests
pub struct RankingOutput {
pub mut:
	model   string
	results []RankResult
	usage   Usage
	object  string
}

// RankResult represents a single reranking result
pub struct RankResult {
pub mut:
	document        RankDocument
	index           int
	relevance_score f64
}

// RankDocument represents a single document for reranking
pub struct RankDocument {
pub mut:
	text string
}

// to_string converts a JinaRerankModel enum to its string representation as expected by the Jina API
pub fn (m JinaRerankModel) to_string() string {
	return match m {
		.reranker_v2_base_multilingual { 'jina-reranker-v2-base-multilingual' }
		.reranker_v1_base_en { 'jina-reranker-v1-base-en' }
		.reranker_v1_tiny_en { 'jina-reranker-v1-tiny-en' }
		.reranker_v1_turbo_en { 'jina-reranker-v1-turbo-en' }
		.colbert_v1_en { 'jina-colbert-v1-en' }
	}
}

// from_string converts a string to a JinaRerankModel enum, returning an error if the string is invalid
pub fn jina_rerank_model_from_string(s string) !JinaRerankModel {
	return match s {
		'jina-reranker-v2-base-multilingual' { JinaRerankModel.reranker_v2_base_multilingual }
		'jina-reranker-v1-base-en' { JinaRerankModel.reranker_v1_base_en }
		'jina-reranker-v1-tiny-en' { JinaRerankModel.reranker_v1_tiny_en }
		'jina-reranker-v1-turbo-en' { JinaRerankModel.reranker_v1_turbo_en }
		'jina-colbert-v1-en' { JinaRerankModel.colbert_v1_en }
		else { return error('Invalid JinaRerankModel string: ${s}') }
	}
}

@[params]
pub struct RerankParams {
pub mut:
	model            JinaRerankModel @[required]
	query            string          @[required]
	documents        []string        @[required]
	top_n            ?int  // Optional: Number of top results to return
	return_documents ?bool // Optional: Flag to determine if the documents should be returned
}

// Rerank documents based on a query
pub fn (mut j Jina) rerank(params RerankParams) !RankingOutput {
	mut rank_input := RerankInput{
		model:     params.model.to_string()
		query:     params.query
		documents: params.documents
	}

	if v := params.top_n {
		rank_input.top_n = v
	}

	if v := params.return_documents {
		rank_input.return_documents = v
	}

	req := httpconnection.Request{
		method:     .post
		prefix:     'v1/rerank'
		dataformat: .json
		data:       json.encode(rank_input)
	}

	mut httpclient := j.httpclient()!
	response := httpclient.post_json_str(req)!
	return json.decode(RankingOutput, response)!
}
