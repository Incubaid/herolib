module playcmds

import freeflowuniverse.herolib.develop.luadns
import freeflowuniverse.herolib.core.playbook { PlayBook }
// import os

fn play_luadns(mut plbook PlayBook) ! {
	if plbook.exists(filter: 'luadns.') == false {
		return
	}

	// Variables below are not used, commenting them out
	// mut buildroot := '${os.home_dir()}/hero/var/mdbuild'
	// mut publishroot := '${os.home_dir()}/hero/www/info'
	// mut coderoot := ''
	// mut install := false
	// mut reset := false
	// mut pull := false

	for mut action in plbook.find(filter: 'luadns.set_domain')! {
		mut p := action.params
		url := p.get_default('url', '')!

		if url == '' {
			return error('luadns url cant be empty')
		}

		mut dns := luadns.load(url)!

		domain := p.get_default('domain', '')!
		ip := p.get_default('ip', '')!

		if domain == '' || ip == '' {
			return error('luadns set domain: domain or ip cant be empty')
		}

		dns.set_domain(domain, ip)!
		action.done = true
	}
}
