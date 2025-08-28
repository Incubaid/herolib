module hetznermanager

import freeflowuniverse.herolib.core.texttools
import time
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.builder


pub fn (mut h HetznerManager) check_whitelist(name string)! {
	
	if whitelist.len == 0 {
		return
	}
	if !whitelist.contains(name) {
		return error('Server ${name} is not whitelisted')
	}

}
