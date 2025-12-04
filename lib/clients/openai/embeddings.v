module openai

import json

// pub enum EmbeddingModel {
// 	text_embedding_ada
// }

// fn embedding_model_str(e EmbeddingModel) string {
// 	return match e {
// 		.text_embedding_ada {
// 			'text-embedding-ada-002'
// 		}
// 	}
// }

@[params]
pub struct EmbeddingCreateRequest {
pub mut:
	input []string @[required]
	model string
	user  string
}

pub struct Embedding {
pub mut:
	object    string
	embedding []f32
	index     int
}

pub struct EmbeddingResponse {
pub mut:
	object string
	data   []Embedding
	model  string
	usage  Usage
}

pub fn (mut f OpenAI) embed(args_ EmbeddingCreateRequest) !EmbeddingResponse {
	mut args := args_
	if args.model == '' {
		args.model = f.model_default
	}
	data := json.encode(args)
	mut conn := f.connection()!
	r := conn.post_json_str(prefix: 'embeddings', data: data)!
	return json.decode(EmbeddingResponse, r)!
}
