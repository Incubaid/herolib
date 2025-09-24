module livekit

import jwt
import time

pub struct AccessToken {
pub mut:
	api_key     string
	api_secret  string
	identity    string
	name        string
	ttl         int
	video_grant VideoGrant
}

pub struct VideoGrant {
pub mut:
	room_create      bool
	room_admin       bool
	room_join        bool
	room_list        bool
	can_publish      bool
	can_subscribe    bool
	can_publish_data bool
	room             string
}

pub fn (mut c LivekitClient) new_access_token(identity string, name string, ttl int) !AccessToken {
	return AccessToken{
		api_key:    c.api_key
		api_secret: c.api_secret
		identity:   identity
		name:       name
		ttl:        ttl
	}
}

pub fn (mut t AccessToken) add_video_grant(grant VideoGrant) {
	t.video_grant = grant
}

pub fn (t AccessToken) to_jwt() !string {
	mut claims := jwt.new_claims()
	claims.iss = t.api_key
	claims.sub = t.identity
	claims.exp = time.now().unix_time() + t.ttl
	claims.nbf = time.now().unix_time()
	claims.iat = time.now().unix_time()
	claims.name = t.name
	claims.video = t.video_grant
	return jwt.encode(claims, t.api_secret, .hs256)
}
