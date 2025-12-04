module ipaddr

import os
import incubaid.herolib.core

// Keywords that indicate the current machine's IP should be used
const current_machine_keywords = ['thismachine', 'thisvm', 'device', 'machine', 'current']

// is_current_machine_keyword checks if the given value is a keyword
// indicating the current machine's IP should be used
pub fn is_current_machine_keyword(value string) bool {
	return value.to_lower() in ipaddr.current_machine_keywords
}

// get returns the IP address of the current machine
// Returns an error if no IP address can be determined
pub fn get() !string {
	mut ip := ''

	if core.is_linux()! {
		// Linux: ip addr show | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | sed -n '3p'
		res := os.execute("ip addr show | grep 'inet ' | awk '{print \$2}' | cut -d'/' -f1 | sed -n '3p'")
		if res.exit_code == 0 {
			ip = res.output.trim_space()
		}
	} else if core.is_osx()! {
		// macOS: ifconfig | awk '/inet / {print $2}' | sed -n '3p'
		res := os.execute("ifconfig | awk '/inet / {print \$2}' | sed -n '3p'")
		if res.exit_code == 0 {
			ip = res.output.trim_space()
		}
	} else {
		return error('Unsupported platform for IP address detection')
	}

	if ip.len == 0 {
		return error('This machine does not have a public IP address')
	}

	return ip
}

// get_or_resolve returns the IP address - either the provided value
// or the current machine's IP if the value is a current machine keyword
pub fn get_or_resolve(value string) !string {
	if is_current_machine_keyword(value) {
		return get()!
	}
	return value
}
