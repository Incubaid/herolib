module webdav

import time
import encoding.base64
import incubaid.herolib.core.texttools

fn (server &Server) auth_middleware(mut ctx Context) bool {
	ctx.set_custom_header('Date', texttools.format_rfc1123(time.utc())) or { return false }

	// return true
	auth_header := ctx.get_header(.authorization) or {
		ctx.res.set_status(.unauthorized)
		ctx.set_header(.www_authenticate, 'Basic realm="/"')
		ctx.send_response_to_client('', '')
		return false
	}
	if auth_header == '' {
		ctx.res.set_status(.unauthorized)
		ctx.set_header(.www_authenticate, 'Basic realm="/"')
		ctx.send_response_to_client('', '')
		return false
	}

	if !auth_header.starts_with('Basic ') {
		ctx.res.set_status(.unauthorized)
		ctx.set_header(.www_authenticate, 'Basic realm="/"')
		ctx.send_response_to_client('', '')
		return false
	}
	auth_decoded := base64.decode_str(auth_header[6..])
	split_credentials := auth_decoded.split(':')
	if split_credentials.len != 2 {
		ctx.res.set_status(.unauthorized)
		ctx.set_header(.www_authenticate, 'Basic realm="/"')
		ctx.send_response_to_client('', '')
		return false
	}
	username := split_credentials[0]
	hashed_pass := split_credentials[1]
	if user := server.user_db[username] {
		if user != hashed_pass {
			ctx.res.set_status(.unauthorized)
			ctx.set_header(.www_authenticate, 'Basic realm="/"')
			ctx.send_response_to_client('', '')
			return false
		}
		return true
	}
	ctx.res.set_status(.unauthorized)
	ctx.set_header(.www_authenticate, 'Basic realm="/"')
	ctx.send_response_to_client('', '')
	return false
}
