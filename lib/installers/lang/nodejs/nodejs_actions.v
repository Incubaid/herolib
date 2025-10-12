module nodejs

import incubaid.herolib.ui.console
import incubaid.herolib.installers.ulist
import os

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('node -v')
	if res.exit_code != 0 {
		return false
	}
	return true
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn install() ! {
	console.print_header('Installing Node.js...')
	os.execute('curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -')
	os.execute('sudo apt install -y nodejs')
	console.print_header('Node.js installation complete.')
}

fn destroy() ! {
	console.print_header('Uninstalling Node.js and NVM...')
	os.execute('sudo apt remove -y nodejs')
	os.execute('sudo apt autoremove -y')
	os.rm('~/.nvm') or {}
	console.print_header('Node.js and NVM have been uninstalled.')
}
