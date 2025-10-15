module livekit

import json

pub struct ParticipantInfo {
pub mut:
	sid        string
	identity   string
	state      string
	metadata   string
	joined_at  i64
	name       string
	version    u32
	permission string
	region     string
	publisher  bool
}

pub struct UpdateParticipantArgs {
pub mut:
	room_name  string
	identity   string
	metadata   string
	permission string
}

pub struct MutePublishedTrackArgs {
pub mut:
	room_name string
	identity  string
	track_sid string
	muted     bool
}

pub fn (mut c LivekitClient) list_participants(room_name string) ![]ParticipantInfo {
	mut resp := c.post('twirp/livekit.RoomService/ListParticipants', {
		'room': room_name
	})!
	participants := json.decode[[]ParticipantInfo](resp.body)!
	return participants
}

pub fn (mut c LivekitClient) get_participant(room_name string, identity string) !ParticipantInfo {
	mut resp := c.post('twirp/livekit.RoomService/GetParticipant', {
		'room':     room_name
		'identity': identity
	})!
	participant := json.decode[ParticipantInfo](resp.body)!
	return participant
}

pub fn (mut c LivekitClient) remove_participant(room_name string, identity string) ! {
	_ = c.post('twirp/livekit.RoomService/RemoveParticipant', {
		'room':     room_name
		'identity': identity
	})!
}

pub fn (mut c LivekitClient) update_participant(args UpdateParticipantArgs) ! {
	_ = c.post('twirp/livekit.RoomService/UpdateParticipant', args)!
}

pub fn (mut c LivekitClient) mute_published_track(args MutePublishedTrackArgs) ! {
	_ = c.post('twirp/livekit.RoomService/MutePublishedTrack', args)!
}
