module playcmds

import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.data.atlas
import incubaid.herolib.biz.bizmodel
import incubaid.herolib.threefold.incatokens
import incubaid.herolib.web.site
import incubaid.herolib.virt.hetznermanager
import incubaid.herolib.web.docusaurus
import incubaid.herolib.clients.openai
import incubaid.herolib.clients.giteaclient
import incubaid.herolib.osal.tmux
import incubaid.herolib.installers.base
import incubaid.herolib.installers.lang.vlang
import incubaid.herolib.installers.lang.herolib
import incubaid.herolib.installers.horus.coordinator
import incubaid.herolib.installers.horus.supervisor
import incubaid.herolib.installers.horus.herorunner
import incubaid.herolib.installers.horus.osirisrunner
import incubaid.herolib.installers.horus.salrunner

// -------------------------------------------------------------------
// run – entry point for all HeroScript play‑commands
// -------------------------------------------------------------------

@[params]
pub struct PlayArgs {
pub mut:
	heroscript      string
	heroscript_path string
	plbook          ?PlayBook
	reset           bool
	emptycheck      bool = true
}

pub fn play(args_ PlayArgs) ! {
	return run(args_)
}

pub fn run(args_ PlayArgs) ! {
	mut args := args_
	// println('DEBUG: the args is: ${args}')
	mut plbook := args.plbook or {
		playbook.new(text: args.heroscript, path: args.heroscript_path)!
	}

	// Core actions
	play_core(mut plbook)!

	// Git actions
	play_git(mut plbook)!

	// Tmux actions
	tmux.play(mut plbook)!

	// Business model (e.g. currency, bizmodel)
	bizmodel.play(mut plbook)!

	// OpenAI client
	openai.play(mut plbook)!

	// Website / docs
	site.play(mut plbook)!

	incatokens.play(mut plbook)!
	atlas.play(mut plbook)!
	docusaurus.play(mut plbook)!
	hetznermanager.play(mut plbook)!
	hetznermanager.play2(mut plbook)!

	base.play(mut plbook)!
	herolib.play(mut plbook)!
	vlang.play(mut plbook)!

	giteaclient.play(mut plbook)!

	// Horus
	coordinator.play(mut plbook)!
	supervisor.play(mut plbook)!
	herorunner.play(mut plbook)!
	osirisrunner.play(mut plbook)!
	salrunner.play(mut plbook)!

	if args.emptycheck {
		// Ensure we did not leave any actions un‑processed
		plbook.empty_check()!
	}
}
