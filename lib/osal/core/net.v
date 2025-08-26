module core

import net
import time
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core

pub enum PingResult {
	ok
	timeout     // timeout from ping
	unknownhost // means we don't know the hostname its a dns issue
}

@[params]
pub struct PingArgs {
pub mut:
	address string @[required]
	count   u8  = 1 // the ping is successful if it got count amount of replies from the other side
	timeout u16 = 1 // the time in which the other side should respond in seconds
	retry   u8
}

// if reached in timout result will be True
// address is e.g. 8.8.8.8
// ping means we check if the destination responds
pub fn ping(args PingArgs) !PingResult {
	platform_ := core.platform()!
	mut cmd := 'ping'
	if args.address.contains(':') {
		cmd = 'ping6'
	}
	if platform_ == .osx {
		cmd += ' -c ${args.count} -i ${args.timeout} ${args.address}'
	} else if platform_ == .ubuntu {
		cmd += ' -c ${args.count} -w ${args.timeout} ${args.address}'
	} else {
		return error('Unsupported platform for ping')
	}
	console.print_debug(cmd)
	_ := exec(cmd: cmd, retry: args.retry, timeout: 0, stdout: false) or {
		// println("ping failed.error.\n${err}")
		if err.code() == 9999 {
			return .timeout
		}
		if platform_ == .osx {
			return match err.code() {
				2 {
					.timeout
				}
				68 {
					.unknownhost
				}
				else {
					// println("${err} ${err.code()}")
					return error("can't ping on osx (${err.code()})\n${err}")
				}
			}
		} else if platform_ == .ubuntu {
			return match err.code() {
				1 { .timeout }
				2 { .unknownhost }
				else { error("can't ping on ubuntu (${err.code()})\n${err}") }
			}
		} else {
			panic('bug, should never get here')
		}
	}
	return .ok
}

@[params]
pub struct TcpPortTestArgs {
pub mut:
	address string @[required] // 192.168.8.8
	port    int = 22
	timeout u16 = 2000 // total time in milliseconds to keep on trying
}

// test if a tcp port answers
//```
// address string //192.168.8.8
// port int = 22
// timeout u16 = 2000 // total time in milliseconds to keep on trying
//```
pub fn tcp_port_test(args TcpPortTestArgs) bool {
	start_time := time.now().unix_milli()
	mut run_time := 0.0
	for true {
		run_time = time.now().unix_milli()
		if run_time > start_time + args.timeout {
			return false
		}
		_ = net.dial_tcp('${args.address}:${args.port}') or {
			time.sleep(100 * time.millisecond)
			continue
		}
		// console.print_debug(socket)
		return true
	}
	return false
}

// Returns the public IP address as known on the public side
// Uses resolver4.opendns.com to fetch the IP address
pub fn ipaddr_pub_get() !string {
	cmd := 'dig @resolver4.opendns.com myip.opendns.com +short'
	ipaddr := exec(cmd: cmd)!
	public_ip := ipaddr.output.trim('\n').trim(' \n')
	return public_ip
}

// also check the address is on local interface
pub fn ipaddr_pub_get_check() !string {
	// Check if the public IP matches any local interface
	public_ip := ipaddr_pub_get()!
	if !is_ip_on_local_interface(public_ip)! {
		return error('Public IP ${public_ip} is NOT bound to any local interface (possibly behind a NAT firewall).')
	}
	return public_ip
}

// Check if the public IP matches any of the local network interfaces
pub fn is_ip_on_local_interface(public_ip string) !bool {
	interfaces := exec(cmd: 'ip addr show', stdout: false) or {
		return error('Failed to enumerate network interfaces: ${err}')
	}
	lines := interfaces.output.split('\n')

	// Parse through the `ip addr show` output to find local IPs
	for line in lines {
		if line.contains('inet ') {
			parts := line.trim_space().split(' ')
			if parts.len > 1 {
				local_ip := parts[1].split('/')[0] // Extract the IP address
				if public_ip == local_ip {
					return true
				}
			}
		}
	}
	return false
}
