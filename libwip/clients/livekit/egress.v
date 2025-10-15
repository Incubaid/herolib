module livekit

import json

pub struct EgressInfo {
pub mut:
	egress_id  string
	room_id    string
	status     string
	started_at i64
	ended_at   i64
	error      string
}

pub struct StartRoomCompositeEgressArgs {
pub mut:
	room_name       string
	layout          string
	audio_only      bool
	video_only      bool
	custom_base_url string
}

pub struct StartTrackCompositeEgressArgs {
pub mut:
	room_name      string
	audio_track_id string
	video_track_id string
}

pub struct StartWebEgressArgs {
pub mut:
	url        string
	audio_only bool
	video_only bool
}

pub struct UpdateStreamArgs {
pub mut:
	add_output_urls    []string
	remove_output_urls []string
}

pub fn (mut c LivekitClient) start_room_composite_egress(args StartRoomCompositeEgressArgs) !EgressInfo {
	mut resp := c.post('twirp/livekit.Egress/StartRoomCompositeEgress', args)!
	egress_info := json.decode[EgressInfo](resp.body)!
	return egress_info
}

pub fn (mut c LivekitClient) start_track_composite_egress(args StartTrackCompositeEgressArgs) !EgressInfo {
	mut resp := c.post('twirp/livekit.Egress/StartTrackCompositeEgress', args)!
	egress_info := json.decode[EgressInfo](resp.body)!
	return egress_info
}

pub fn (mut c LivekitClient) start_web_egress(args StartWebEgressArgs) !EgressInfo {
	mut resp := c.post('twirp/livekit.Egress/StartWebEgress', args)!
	egress_info := json.decode[EgressInfo](resp.body)!
	return egress_info
}

pub fn (mut c LivekitClient) update_layout(egress_id string, layout string) !EgressInfo {
	mut resp := c.post('twirp/livekit.Egress/UpdateLayout', {
		'egress_id': egress_id
		'layout':    layout
	})!
	egress_info := json.decode[EgressInfo](resp.body)!
	return egress_info
}

pub fn (mut c LivekitClient) update_stream(egress_id string, args UpdateStreamArgs) !EgressInfo {
	mut resp := c.post('twirp/livekit.Egress/UpdateStream', {
		'egress_id':          egress_id
		'add_output_urls':    args.add_output_urls
		'remove_output_urls': args.remove_output_urls
	})!
	egress_info := json.decode[EgressInfo](resp.body)!
	return egress_info
}

pub fn (mut c LivekitClient) list_egress(room_name string) ![]EgressInfo {
	mut resp := c.post('twirp/livekit.Egress/ListEgress', {
		'room_name': room_name
	})!
	egress_infos := json.decode[[]EgressInfo](resp.body)!
	return egress_infos
}

pub fn (mut c LivekitClient) stop_egress(egress_id string) !EgressInfo {
	mut resp := c.post('twirp/livekit.Egress/StopEgress', {
		'egress_id': egress_id
	})!
	egress_info := json.decode[EgressInfo](resp.body)!
	return egress_info
}
