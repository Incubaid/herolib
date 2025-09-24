module livekit

import json
import net.http

pub struct Room {
pub mut:
	sid                        string
	name                       string
	empty_timeout              u32
	max_participants           u32
	creation_time              i64
	turn_password              string
	enabled_codecs             []string
	metadata                   string
	num_participants           u32
	num_connected_participants u32
	active_recording           bool
}

pub struct CreateRoomArgs {
pub mut:
	name             string
	empty_timeout    u32
	max_participants u32
	metadata         string
}

pub struct UpdateRoomMetadataArgs {
pub mut:
	room_name string
	metadata  string
}

pub fn (mut c LivekitClient) create_room(args CreateRoomArgs) !Room {
	mut resp := c.post('twirp/livekit.RoomService/CreateRoom', args)!
	room := json.decode[Room](resp.body)!
	return room
}

pub fn (mut c LivekitClient) delete_room(room_name string) ! {
	_ = c.post('twirp/livekit.RoomService/DeleteRoom', {
		'room': room_name
	})!
}

pub fn (mut c LivekitClient) update_room_metadata(args UpdateRoomMetadataArgs) ! {
	_ = c.post('twirp/livekit.RoomService/UpdateRoomMetadata', args)!
}
