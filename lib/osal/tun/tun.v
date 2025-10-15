module tun

import os
import incubaid.herolib.core

// available checks if TUN/TAP is available on the system
pub fn available() !bool {
	if core.is_linux()! {
		// Check if /dev/net/tun exists and is a character device
		if !os.exists('/dev/net/tun') {
			return false
		}
		// Try to get file info to verify it's a character device
		res := os.execute('test -c /dev/net/tun')
		return res.exit_code == 0
	} else if core.is_osx()! {
		// On macOS, check for utun interfaces
		res := os.execute('ifconfig | grep utun')
		if res.exit_code == 0 && res.output.len > 0 {
			return true
		}
		// Also try sysctl as alternative check
		res2 := os.execute('sysctl -a | grep net.inet.ip.tun')
		return res2.exit_code == 0 && res2.output.len > 0
	}
	return error('Unsupported platform')
}

// free returns the name of an available TUN interface e.g. returns 'utun1'
pub fn free() !string {
	if core.is_linux()! {
		// Try tun0 through tun10
		for i in 1 .. 11 {
			name := 'tun${i}'
			res := os.execute('ip link show ${name}')
			if res.exit_code != 0 {
				// Interface doesn't exist, so it's free
				return name
			}
		}
		return error('No free tun interface found')
	} else if core.is_osx()! {
		// On macOS, list existing utun interfaces to find highest number
		res := os.execute('ifconfig | grep utun')
		if res.exit_code != 0 {
			// No utun interfaces exist, so utun0 would be next
			return 'utun0'
		}
		// Find highest utun number
		mut max_num := -1
		lines := res.output.split('\n')
		for line in lines {
			if line.starts_with('utun') {
				mynum := line[4..].all_before(':').int()
				if mynum > max_num {
					max_num = mynum
				}
			}
		}
		// Next available number
		return 'utun${max_num + 1}'
	}
	return error('Unsupported platform')
}
