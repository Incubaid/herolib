module heroserver

import veb

@['/doc/:handler_type']
pub fn (mut server HeroServer) doc_handler(mut ctx Context, handler_type string) veb.Result {

	//TODO: use the templates doc.html...
	// use the DocSpec
	panic("implement")
	
	return ctx.html(html_content)
}