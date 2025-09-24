module audio

import json
import freeflowuniverse.herolib.core.httpconnection
import os
import net.http
import freeflowuniverse.herolib.clients.openai { OpenAI }

type OpenAIAlias = OpenAI

pub enum Voice {
	alloy
	ash
	coral
	echo
	fable
	onyx
	nova
	sage
	shimmer
}

fn voice_str(x Voice) string {
	return match x {
		.alloy {
			'alloy'
		}
		.ash {
			'ash'
		}
		.coral {
			'coral'
		}
		.echo {
			'echo'
		}
		.fable {
			'fable'
		}
		.onyx {
			'onyx'
		}
		.nova {
			'nova'
		}
		.sage {
			'sage'
		}
		.shimmer {
			'shimmer'
		}
	}
}

pub enum AudioFormat {
	mp3
	opus
	aac
	flac
	wav
	pcm
}

fn audio_format_str(x AudioFormat) string {
	return match x {
		.mp3 {
			'mp3'
		}
		.opus {
			'opus'
		}
		.aac {
			'aac'
		}
		.flac {
			'flac'
		}
		.wav {
			'wav'
		}
		.pcm {
			'pcm'
		}
	}
}

pub enum AudioRespType {
	json
	text
	srt
	verbose_json
	vtt
}

const audio_model = 'whisper-1'
const audio_mime_types = {
	'.mp3':  'audio/mpeg'
	'.mp4':  'audio/mp4'
	'.mpeg': 'audio/mpeg'
	'.mpga': 'audio/mp4'
	'.m4a':  'audio/mp4'
	'.wav':  'audio/vnd.wav'
	'.webm': 'application/octet-stream'
}

fn audio_resp_type_str(i AudioRespType) string {
	return match i {
		.json {
			'json'
		}
		.text {
			'text'
		}
		.srt {
			'srt'
		}
		.verbose_json {
			'verbose_json'
		}
		.vtt {
			'vtt'
		}
	}
}

@[params]
pub struct AudioArgs {
pub mut:
	filepath        string
	prompt          string
	response_format AudioRespType
	temperature     int
	language        string
}

pub struct AudioResponse {
pub mut:
	text string
}

// create transcription from an audio file
// supported audio formats are mp3, mp4, mpeg, mpga, m4a, wav, or webm
pub fn (mut f OpenAIAlias) create_transcription(args AudioArgs) !AudioResponse {
	return f.create_audio_request(args, 'audio/transcriptions')
}

// create translation to english from an audio file
// supported audio formats are mp3, mp4, mpeg, mpga, m4a, wav, or webm
pub fn (mut f OpenAIAlias) create_tranlation(args AudioArgs) !AudioResponse {
	return f.create_audio_request(args, 'audio/translations')
}

fn (mut f OpenAIAlias) create_audio_request(args AudioArgs, endpoint string) !AudioResponse {
	file_content := os.read_file(args.filepath)!
	ext := os.file_ext(args.filepath)
	mut file_mime_type := ''
	if ext in audio_mime_types {
		file_mime_type = audio_mime_types[ext]
	} else {
		return error('file extenion not supported')
	}

	file_data := http.FileData{
		filename:     os.base(args.filepath)
		content_type: file_mime_type
		data:         file_content
	}

	form := http.PostMultipartFormConfig{
		files: {
			'file': [file_data]
		}
		form:  {
			'model':           audio_model
			'prompt':          args.prompt
			'response_format': audio_resp_type_str(args.response_format)
			'temperature':     args.temperature.str()
			'language':        args.language
		}
	}

	req := httpconnection.Request{
		prefix: endpoint
	}

	mut conn := f.connection()!
	r := conn.post_multi_part(req, form)!
	if r.status_code != 200 {
		return error('got error from server: ${r.body}')
	}
	return json.decode(AudioResponse, r.body)!
}

@[params]
pub struct CreateSpeechArgs {
pub:
	model           string = 'tts_1'
	input           string @[required]
	voice           Voice       = .alloy
	response_format AudioFormat = .mp3
	speed           f32         = 1.0
	output_path     string @[required]
}

pub struct CreateSpeechRequest {
pub:
	model           string
	input           string
	voice           string
	response_format string
	speed           f32
}

pub fn (mut f OpenAIAlias) create_speech(args CreateSpeechArgs) ! {
	mut output_file := os.open_file(args.output_path, 'w+')!

	req := CreateSpeechRequest{
		model:           args.model
		input:           args.input
		voice:           voice_str(args.voice)
		response_format: audio_format_str(args.response_format)
		speed:           args.speed
	}
	data := json.encode(req)

	mut conn := f.connection()!
	r := conn.post_json_str(prefix: 'audio/speech', data: data)!

	output_file.write(r.bytes())!
}
