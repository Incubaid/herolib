module docusaurus

import os
import incubaid.herolib.core.pathlib
import incubaid.herolib.web.site
import incubaid.herolib.osal.core as osal
import incubaid.herolib.osal.rsync
import incubaid.herolib.ui.console

@[heap]
pub struct DocSite {
pub mut:
	name string
	url  string
	// path_src     pathlib.Path
	path_publish pathlib.Path
	path_build   pathlib.Path
	errors       []SiteError
	config       Configuration
	website      site.Site
	generated    bool
}

pub fn (mut s DocSite) build() ! {
	s.generate()!
	osal.exec(
		cmd:   '
			cd ${s.path_build.path}
			bun run build
			'
		retry: 0
	)!
}

pub fn (mut s DocSite) build_dev_publish() ! {
	s.generate()!
	osal.exec(
		cmd:   '
			cd ${s.path_build.path}
			bun run buildp
			'
		retry: 0
	)!
}

pub fn (mut s DocSite) build_publish() ! {
	s.generate()!
	osal.exec(
		cmd:   '
			cd ${s.path_build.path}
			bun run build
			'
		retry: 0
	)!

	// If no publish destinations configured, create default one using site name
	mut destinations := s.website.siteconfig.build_dest.clone()
	if destinations.len == 0 {
		destinations << site.BuildDest{
			site_name: s.website.siteconfig.name
		}
	}

	for mut item in destinations {
		// Default site_name to the site's configured name if not explicitly set
		if item.site_name == '' {
			item.site_name = s.website.siteconfig.name
		}
		if item.site_name == '' {
			return error('site_name is required (e.g., "info", "manual")')
		}
		// Get password from env if not set
		if item.rsync_password == '' {
			item.rsync_password = os.getenv('RSYNCD_SECRET')
		}
		if item.rsync_password == '' {
			return error('rsync_password is required. Set RSYNCD_SECRET env var.')
		}

		// Build the full module path: module/site_name (e.g., 'sites/geomind_memo')
		// - rsync_module: the rsync daemon module name configured on the server (e.g., "sites")
		// - site_name: subdirectory within that module for this specific site (defaults to site name)
		// Result: atlas@51.195.61.5::sites/geomind_memo/
		module_path := '${item.rsync_module}/${item.site_name}'

		console.print_item('publishing to rsync daemon: ${item.rsync_user}@${item.rsync_host}::${module_path}')
		rsync.rsync(
			source:        '${s.path_build.path}/build'
			daemon_mode:   true
			daemon_host:   item.rsync_host
			daemon_port:   item.rsync_port
			daemon_user:   item.rsync_user
			daemon_module: module_path
			password:      item.rsync_password
			delete:        true
		)!
	}
}

@[params]
pub struct DevArgs {
pub mut:
	host          string = 'localhost'
	port          int    = 3000
	open          bool   = true  // whether to open the browser automatically
	watch_changes bool // whether to watch for changes in docs and rebuild automatically
	skip_generate bool // whether to skip generation (useful when docs are pre-generated, e.g., from atlas)
}

pub fn (mut s DocSite) open(args DevArgs) ! {
	// Print instructions for user
	console.print_item('open browser: https://${args.host}:${args.port}')
	osal.exec(cmd: 'open https://${args.host}:${args.port}')!
}

pub fn (mut s DocSite) dev(args DevArgs) ! {
	if !args.skip_generate {
		s.generate()!
	}
	osal.exec(
		cmd:   '
			cd ${s.path_build.path}
			bun run start -p ${args.port} -h ${args.host}
			'
		retry: 0
	)!
	s.open()!
}

@[params]
pub struct ErrorArgs {
pub mut:
	path string
	msg  string
	cat  ErrorCat
}

pub fn (mut s DocSite) error(args ErrorArgs) {
	// path2 := pathlib.get(args.path)
	e := SiteError{
		path: args.path
		msg:  args.msg
		cat:  args.cat
	}
	s.errors << e
	console.print_stderr(args.msg)
}
