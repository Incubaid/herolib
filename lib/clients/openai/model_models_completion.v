module openai

struct ChatCompletionRaw {
mut:
	id      string
	object  string
	created u32
	choices []ChoiceRaw
	usage   Usage
}

struct ChoiceRaw {
mut:
	index         int
	message       MessageRaw
	finish_reason string
}

struct MessageRaw {
mut:
	role    string
	content string
}

struct ChatMessagesRaw {
mut:
	model                 string
	messages              []MessageRaw
	temperature           f64 = 0.5
	max_completion_tokens int = 32000
}
