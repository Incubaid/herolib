#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.osal.tun

// Check if TUN is available
if available := tun.available() {
	if available {
		println('TUN is available on this system')

		// Get a free TUN interface name
		if interface_name := tun.free() {
			println('Found free TUN interface: ${interface_name}')

			// Example: Now you could use this interface name
			// to set up your tunnel
		} else {
			println('Error finding free interface: ${err}')
		}
	} else {
		println('TUN is not available on this system')
	}
} else {
	println('Error checking TUN availability: ${err}')
}
