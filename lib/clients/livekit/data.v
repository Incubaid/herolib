module livekit

pub struct SendDataArgs {
pub mut:
	room_name        string
	data             []u8
	kind             DataPacket_Kind
	destination_sids []string
}

pub enum DataPacket_Kind {
	reliable
	lossy
}

pub fn (mut c LivekitClient) send_data(args SendDataArgs) ! {
	_ = c.post('twirp/livekit.RoomService/SendData', args)!
}
