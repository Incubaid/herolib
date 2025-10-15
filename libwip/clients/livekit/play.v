module livekit

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.core.texttools
import incubaid.herolib.ui.console

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'livekit.') {
		return
	}

	// Handle livekit.init - configure the client
	if plbook.exists_once(filter: 'livekit.init') {
		mut action := plbook.get(filter: 'livekit.init')!
		mut p := action.params

		name := texttools.name_fix(p.get_default('name', 'default')!)
		url := p.get('url')!
		api_key := p.get('api_key')!
		api_secret := p.get('api_secret')!

		mut client := LivekitClient{
			name:       name
			url:        url
			api_key:    api_key
			api_secret: api_secret
		}

		set(client)!
		console.print_header('LiveKit client "${name}" configured')
		action.done = true
	}

	// Handle room creation
	mut room_create_actions := plbook.find(filter: 'livekit.room_create')!
	for mut action in room_create_actions {
		mut p := action.params

		client_name := texttools.name_fix(p.get_default('client', 'default')!)
		room_name := p.get('name')!
		empty_timeout := p.get_u32_default('empty_timeout', 300)!
		max_participants := p.get_u32_default('max_participants', 50)!
		metadata := p.get_default('metadata', '')!

		mut client := get(name: client_name)!

		room := client.create_room(
			name:             room_name
			empty_timeout:    empty_timeout
			max_participants: max_participants
			metadata:         metadata
		)!

		console.print_header('Room "${room_name}" created successfully')
		action.done = true
	}

	// Handle room deletion
	mut room_delete_actions := plbook.find(filter: 'livekit.room_delete')!
	for mut action in room_delete_actions {
		mut p := action.params

		client_name := texttools.name_fix(p.get_default('client', 'default')!)
		room_name := p.get('name')!

		mut client := get(name: client_name)!
		client.delete_room(room_name)!

		console.print_header('Room "${room_name}" deleted successfully')
		action.done = true
	}

	// Handle participant removal
	mut participant_remove_actions := plbook.find(filter: 'livekit.participant_remove')!
	for mut action in participant_remove_actions {
		mut p := action.params

		client_name := texttools.name_fix(p.get_default('client', 'default')!)
		room_name := p.get('room')!
		identity := p.get('identity')!

		mut client := get(name: client_name)!
		client.remove_participant(room_name, identity)!

		console.print_header('Participant "${identity}" removed from room "${room_name}"')
		action.done = true
	}

	// Handle participant mute/unmute
	mut participant_mute_actions := plbook.find(filter: 'livekit.participant_mute')!
	for mut action in participant_mute_actions {
		mut p := action.params

		client_name := texttools.name_fix(p.get_default('client', 'default')!)
		room_name := p.get('room')!
		identity := p.get('identity')!
		track_sid := p.get('track_sid')!
		muted := p.get_default_true('muted')

		mut client := get(name: client_name)!
		client.mute_published_track(
			room_name: room_name
			identity:  identity
			track_sid: track_sid
			muted:     muted
		)!

		status := if muted { 'muted' } else { 'unmuted' }
		console.print_header('Track "${track_sid}" ${status} for participant "${identity}"')
		action.done = true
	}

	// Handle room metadata update
	mut room_update_actions := plbook.find(filter: 'livekit.room_update')!
	for mut action in room_update_actions {
		mut p := action.params

		client_name := texttools.name_fix(p.get_default('client', 'default')!)
		room_name := p.get('room')!
		metadata := p.get('metadata')!

		mut client := get(name: client_name)!
		client.update_room_metadata(
			room_name: room_name
			metadata:  metadata
		)!

		console.print_header('Room "${room_name}" metadata updated')
		action.done = true
	}

	// Handle access token generation
	mut token_create_actions := plbook.find(filter: 'livekit.token_create')!
	// for mut action in token_create_actions {
	// 	mut p := action.params

	// 	client_name := texttools.name_fix(p.get_default('client', 'default')!)
	// 	identity := p.get('identity')!
	// 	name := p.get_default('name', identity)!
	// 	room := p.get_default('room', '')!
	// 	ttl := p.get_int_default('ttl', 21600)!
	// 	can_publish := p.get_default_false('can_publish')
	// 	can_subscribe := p.get_default_true('can_subscribe')
	// 	can_publish_data := p.get_default_false('can_publish_data')

	// 	mut client := get(name: client_name)!

	// 	mut token := client.new_access_token(
	// 		identity: identity
	// 		name:     name
	// 		ttl:      ttl
	// 	)!

	// 	token.add_video_grant(VideoGrant{
	// 		room:             room
	// 		room_join:        true
	// 		can_publish:      can_publish
	// 		can_subscribe:    can_subscribe
	// 		can_publish_data: can_publish_data
	// 	})

	// 	jwt := token.to_jwt()!
	// 	console.print_header('Access token generated for "${identity}"')
	// 	console.print_debug('Token: ${jwt}')
	// 	action.done = true
	// }
}
