module hostsfile

import os
import incubaid.herolib.osal.core as osal

const hosts_file_path = '/etc/hosts'

@[heap]
pub struct HostsFile {
pub mut:
	sections []Section
}

pub struct Section {
pub mut:
	name  string
	hosts []Host
}

pub struct Host {
pub mut:
	ip     string
	domain string
}

// new creates a new HostsFile instance by reading the system's hosts file
pub fn new() !HostsFile {
	mut obj := HostsFile{}
	mut content := os.read_file(hosts_file_path) or {
		return error('Failed to read hosts file: ${err}')
	}
	mut current_section := Section{
		name: ''
	}

	for line in content.split_into_lines() {
		trimmed := line.trim_space()
		if trimmed == '' {
			continue
		}

		if trimmed.starts_with('#') {
			// If we have hosts in the current section, add it to sections
			if current_section.hosts.len > 0 {
				obj.sections << current_section
			}
			// Start a new section
			current_section = Section{
				name: trimmed[1..].trim_space()
			}
			continue
		}

		// Parse host entries
		parts := trimmed.fields()
		if parts.len >= 2 {
			current_section.hosts << Host{
				ip:     parts[0]
				domain: parts[1]
			}
		}
	}

	// Add the last section if it has hosts
	if current_section.hosts.len > 0 {
		obj.sections << current_section
	}

	return obj
}

// add_host adds a new host entry to the specified section
pub fn (mut h HostsFile) add_host(ip string, domain string, section string) ! {
	// Validate inputs
	if ip == '' {
		return error('IP address cannot be empty')
	}
	if domain == '' {
		return error('Domain cannot be empty')
	}

	// Check if domain already exists
	if h.exists(domain) {
		return error('Domain ${domain} already exists in hosts file')
	}

	// Find or create section
	mut found_section := false
	for mut s in h.sections {
		if s.name == section {
			s.hosts << Host{
				ip:     ip
				domain: domain
			}
			found_section = true
			break
		}
	}

	if !found_section {
		h.sections << Section{
			name:  section
			hosts: [Host{
				ip:     ip
				domain: domain
			}]
		}
	}
}

// remove_host removes all entries for the specified domain
pub fn (mut h HostsFile) remove_host(domain string) ! {
	mut found := false
	for mut section in h.sections {
		// Filter out hosts with matching domain
		old_len := section.hosts.len
		section.hosts = section.hosts.filter(it.domain != domain)
		if section.hosts.len < old_len {
			found = true
		}
	}

	if !found {
		return error('Domain ${domain} not found in hosts file')
	}
}

// exists checks if a domain exists in any section
pub fn (h &HostsFile) exists(domain string) bool {
	for section in h.sections {
		for host in section.hosts {
			if host.domain == domain {
				return true
			}
		}
	}
	return false
}

// save writes the hosts file back to disk
pub fn (h &HostsFile) save() ! {
	mut content := ''

	for section in h.sections {
		if section.name != '' {
			content += '# ${section.name}\n'
		}

		for host in section.hosts {
			content += '${host.ip}\t${host.domain}\n'
		}
		content += '\n'
	}

	// Check if we're on macOS
	is_macos := os.user_os() == 'macos'

	if is_macos {
		// On macOS, we need to use sudo
		osal.execute_interactive('sudo -- sh -c -e "echo \'${content}\' > ${hosts_file_path}"') or {
			return error('Failed to write hosts file with sudo: ${err}')
		}
	} else {
		// On Linux, try direct write first, fallback to sudo if needed
		os.write_file(hosts_file_path, content) or {
			// If direct write fails, try with sudo
			osal.execute_interactive('sudo -- sh -c -e "echo \'${content}\' > ${hosts_file_path}"') or {
				return error('Failed to write hosts file: ${err}')
			}
		}
	}
}

// remove_section removes an entire section and its hosts
pub fn (mut h HostsFile) remove_section(section_name string) ! {
	mut found := false
	for i, section in h.sections {
		if section.name == section_name {
			h.sections.delete(i)
			found = true
			break
		}
	}

	if !found {
		return error('Section ${section_name} not found')
	}
}

// clear_section removes all hosts from a section but keeps the section
pub fn (mut h HostsFile) clear_section(section_name string) ! {
	mut found := false
	for mut section in h.sections {
		if section.name == section_name {
			section.hosts.clear()
			found = true
			break
		}
	}

	if !found {
		return error('Section ${section_name} not found')
	}
}
