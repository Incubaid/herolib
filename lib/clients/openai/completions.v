module openai

import json

@[params]
pub struct CompletionArgs {
pub mut:
	model                 string
	messages              []Message // optional because we can use message, which means we just pass a string
	message               string
	temperature           f64 = 0.2
	max_completion_tokens int = 32000
}

struct Message {
mut:
	role    RoleType
	content string
}

pub enum RoleType {
	system
	user
	assistant
	function
}

fn roletype_str(x RoleType) string {
	return match x {
		.system {
			'system'
		}
		.user {
			'user'
		}
		.assistant {
			'assistant'
		}
		.function {
			'function'
		}
	}
}

struct Usage {
mut:
	prompt_tokens     int
	completion_tokens int
	total_tokens      int
}

struct ChatCompletion {
mut:
	id      string
	created u32
	result  string
	usage   Usage
}

// creates a new chat completion given a list of messages
// each message consists of message content and the role of the author
pub fn (mut f OpenAI) chat_completion(args_ CompletionArgs) !ChatCompletion {
	mut args := args_
	if args.model == '' {
		args.model = f.model_default
	}
	mut m := ChatMessagesRaw{
		model:                 args.model
		temperature:           args.temperature
		max_completion_tokens: args.max_completion_tokens
	}
	for msg in args.messages {
		mr := MessageRaw{
			role:    roletype_str(msg.role)
			content: msg.content
		}
		m.messages << mr
	}
	if args.message != '' {
		mr := MessageRaw{
			role:    'user'
			content: args.message
		}
		m.messages << mr
	}
	data := json.encode(m)
	// println('data: ${data}')
	mut conn := f.connection()!
	r := conn.post_json_str(prefix: 'chat/completions', data: data)!

	res := json.decode(ChatCompletionRaw, r)!

	mut result := ''
	for choice in res.choices {
		result += choice.message.content
	}

	mut chat_completion_result := ChatCompletion{
		id:      res.id
		created: res.created
		result:  result
		usage:   res.usage
	}
	return chat_completion_result
}
