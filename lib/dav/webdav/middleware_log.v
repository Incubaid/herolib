module webdav

import incubaid.herolib.ui.console
import log

fn middleware_log_request(mut ctx Context) bool {
	log.debug('[WebDAV] Request: ${ctx.req.method.str()} ${ctx.req.url}')
	return true
}

fn middleware_log_response(mut ctx Context) bool {
	log.debug('[WebDAV] Response: ${ctx.req.url} ${ctx.res.status()}\n')
	return true
}
