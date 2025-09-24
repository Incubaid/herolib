module livekit

import net.http
import json
import time

fn (mut c LivekitClient) post(path string, body any) !http.Response {
	mut token := c.new_access_token(
		identity: 'api'
		name:     'API User'
		ttl:      10 * 60 // 10 minutes
	)!
	token.add_video_grant(VideoGrant{
		room_create: true
		room_admin:  true
		room_list:   true
	})
	jwt := token.to_jwt()!

	mut header := http.new_header()
	header.add('Authorization', 'Bearer ' + jwt)!
	header.add('Content-Type', 'application/json')!

	url := '${c.url}/${path}'
	data := json.encode(body)
	mut req := http.Request{
		method: .post
		url:    url
		header: header
		data:   data
	}
	resp := http.fetch(req)!
	if resp.status_code != 200 {
		return error('failed to execute request: ${resp.body}')
	}
	return resp
}
