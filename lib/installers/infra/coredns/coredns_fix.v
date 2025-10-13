module coredns

import os
import net
import incubaid.herolib.ui.console

fn is_systemd_resolved_active() bool {
	result := os.execute('systemctl is-active systemd-resolved')
	return result.exit_code == 0 && result.output.trim_space() == 'active'
}

fn disable_systemd_resolved() {
	console.print_debug('Stopping and disabling systemd-resolved...')
	os.execute('sudo systemctl stop systemd-resolved')
	os.execute('sudo systemctl disable systemd-resolved')
	os.execute('sudo systemctl mask systemd-resolved')
}

fn is_dns_port_free() bool {
	result := os.execute("sudo ss -tunlp | grep ':53 '")
	return result.exit_code != 0
}

fn set_local_dns() {
	console.print_debug('Updating /etc/resolv.conf to use local DNS...')
	os.execute('sudo rm -f /etc/resolv.conf')
	os.write_file('/etc/resolv.conf', 'nameserver 127.0.0.1\n') or {
		console.print_debug('Failed to update /etc/resolv.conf')
		return
	}
	console.print_debug('/etc/resolv.conf updated successfully.')
}

fn set_global_dns() {
	console.print_debug('Updating /etc/resolv.conf to use local DNS...')
	os.execute('sudo rm -f /etc/resolv.conf')
	os.write_file('/etc/resolv.conf', 'nameserver 8.8.8.8\n') or {
		console.print_debug('Failed to update /etc/resolv.conf')
		return
	}
	console.print_debug('/etc/resolv.conf updated successfully for global.')
}

pub fn fix() ! {
	console.print_debug('Checking if systemd-resolved is active...')
	if is_systemd_resolved_active() {
		disable_systemd_resolved()
	} else {
		println('systemd-resolved is already disabled.')
	}

	console.print_debug('Checking if DNS UDP port 53 is free...')
	if is_dns_port_free() {
		console.print_debug('UDP port 53 is free.')
	} else {
		console.print_debug('UDP port 53 is still in use. Ensure CoreDNS or another service is properly set up.')
		return
	}

	set_global_dns()
	console.print_debug('Setup complete. Ensure CoreDNS is running.')
}
