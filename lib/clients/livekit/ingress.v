module livekit

import json

pub struct IngressInfo {
pub mut:
	ingress_id string
	name       string
	stream_key string
	url        string
	input_type IngressInput
	audio      IngressAudioOptions
	video      IngressVideoOptions
	state      IngressState
}

pub enum IngressInput {
	rtmp_input
	whip_input
}

pub struct IngressAudioOptions {
pub mut:
	name   string
	source TrackSource
	preset AudioPreset
}

pub struct IngressVideoOptions {
pub mut:
	name   string
	source TrackSource
	preset VideoPreset
}

pub enum TrackSource {
	camera
	microphone
	screen_share
	screen_share_audio
}

pub enum AudioPreset {
	opus_stereo_96kbps
	opus_mono_64kbps
}

pub enum VideoPreset {
	h264_720p_30fps_3mbps
	h264_1080p_30fps_4_5mbps
	h264_540p_25fps_2mbps
}

pub struct IngressState {
pub mut:
	status     IngressStatus
	error      string
	video      InputVideoState
	audio      InputAudioState
	room_id    string
	started_at i64
}

pub enum IngressStatus {
	endpoint_inactive
	endpoint_buffering
	endpoint_publishing
}

pub struct InputVideoState {
pub mut:
	mime_type string
	width     u32
	height    u32
	framerate u32
}

pub struct InputAudioState {
pub mut:
	mime_type   string
	channels    u32
	sample_rate u32
}

pub struct CreateIngressArgs {
pub mut:
	name                 string
	room_name            string
	participant_identity string
	participant_name     string
	input_type           IngressInput
	audio                IngressAudioOptions
	video                IngressVideoOptions
}

pub fn (mut c LivekitClient) create_ingress(args CreateIngressArgs) !IngressInfo {
	mut resp := c.post('twirp/livekit.Ingress/CreateIngress', args)!
	ingress_info := json.decode[IngressInfo](resp.body)!
	return ingress_info
}

pub struct UpdateIngressArgs {
pub mut:
	ingress_id           string
	name                 string
	room_name            string
	participant_identity string
	participant_name     string
	audio                IngressAudioOptions
	video                IngressVideoOptions
}

pub fn (mut c LivekitClient) update_ingress(args UpdateIngressArgs) !IngressInfo {
	mut resp := c.post('twirp/livekit.Ingress/UpdateIngress', {
		'ingress_id':           args.ingress_id
		'name':                 args.name
		'room_name':            args.room_name
		'participant_identity': args.participant_identity
		'participant_name':     args.participant_name
		'audio':                args.audio
		'video':                args.video
	})!
	ingress_info := json.decode[IngressInfo](resp.body)!
	return ingress_info
}

pub fn (mut c LivekitClient) list_ingress(room_name string) ![]IngressInfo {
	mut resp := c.post('twirp/livekit.Ingress/ListIngress', {
		'room_name': room_name
	})!
	ingress_infos := json.decode[[]IngressInfo](resp.body)!
	return ingress_infos
}

pub fn (mut c LivekitClient) delete_ingress(ingress_id string) !IngressInfo {
	mut resp := c.post('twirp/livekit.Ingress/DeleteIngress', {
		'ingress_id': ingress_id
	})!
	ingress_info := json.decode[IngressInfo](resp.body)!
	return ingress_info
}
