module core

import os
import net

// Check if a port is available (free) on the local machine
// Returns an error if the port is already in use
pub fn port_check_available(port int) ! {
	$if macos {
		// On macOS, try lsof first, then fallback to netstat, then socket binding
		if check_port_with_lsof(port)! {
			return
		}
		// If lsof failed, try netstat as fallback
		if check_port_with_netstat(port)! {
			return
		}
		// If both failed, use socket binding as final fallback
		check_port_with_socket_binding(port)!
	} $else $if linux {
		// On Linux, try ss first, then netstat, then socket binding
		if check_port_with_ss(port)! {
			return
		}
		// If ss failed, try netstat as fallback
		if check_port_with_netstat(port)! {
			return
		}
		// If both failed, use socket binding as final fallback
		check_port_with_socket_binding(port)!
	} $else {
		// For other platforms, use socket binding directly
		check_port_with_socket_binding(port)!
	}
	// If we reach here, the port is available
}

// Check port availability using lsof (macOS/Linux)
fn check_port_with_lsof(port int) !bool {
	// First check if lsof is available
	lsof_check := os.execute('which lsof')
	if lsof_check.exit_code != 0 {
		return false // lsof not available, caller should try another method
	}

	result := os.execute('lsof -i :${port}')
	if result.exit_code == 0 {
		// Port is in use, extract process info from lsof output
		lines := result.output.split('\n')
		if lines.len > 1 {
			// Parse the first process line to get basic info
			fields := lines[1].split_any(' \t').filter(it.len > 0)
			if fields.len >= 2 {
				process_name := fields[0]
				pid := fields[1]
				return error('Port ${port} is already in use by process "${process_name}" (PID: ${pid})')
			}
		}
		return error('Port ${port} is already in use')
	}
	return true // Port is available
}

// Check port availability using ss (Linux)
fn check_port_with_ss(port int) !bool {
	// First check if ss is available
	ss_check := os.execute('which ss')
	if ss_check.exit_code != 0 {
		return false // ss not available, caller should try another method
	}

	result := os.execute('ss -tulpn | grep ":${port} "')
	if result.exit_code == 0 {
		// Port is in use, extract process info from ss output
		lines := result.output.split('\n')
		if lines.len > 0 && lines[0].len > 0 {
			// ss output format: proto recv-q send-q local_address:port peer_address:port process
			fields := lines[0].split_any(' \t').filter(it.len > 0)
			if fields.len >= 6 {
				protocol := fields[0]
				local_addr := fields[4]
				process_info := fields[6] // Usually contains "users:(("process",pid,fd))"
				return error('Port ${port} is already in use by ${protocol} service at ${local_addr} (${process_info})')
			}
		}
		return error('Port ${port} is already in use')
	}
	return true // Port is available
}

// Check port availability using netstat (cross-platform fallback)
fn check_port_with_netstat(port int) !bool {
	// First check if netstat is available
	netstat_check := os.execute('which netstat')
	if netstat_check.exit_code != 0 {
		return false // netstat not available, caller should try another method
	}

	// Use netstat to check for listening ports
	mut result := os.Result{}
	$if windows {
		result = os.execute('netstat -an | findstr ":${port} "')
	} $else {
		result = os.execute('netstat -tuln | grep ":${port} "')
	}

	if result.exit_code == 0 {
		// Port is in use
		return error('Port ${port} is already in use (detected by netstat)')
	}
	return true // Port is available
}

// Check port availability by attempting to bind to it (most reliable fallback)
fn check_port_with_socket_binding(port int) ! {
	// Try to create a TCP listener on the port
	mut listener := net.listen_tcp(.ip, ':${port}') or {
		return error('Port ${port} is already in use')
	}
	// If we successfully bound to the port, close it immediately
	listener.close() or {}
	// Port is available
}
