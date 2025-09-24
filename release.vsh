#!/usr/bin/env -S v run

import os
import net.http
import x.json2 as json
import regex

struct GithubRelease {
	tag_name string
}

fn get_latest_release() !string {
	url := 'https://api.github.com/repos/freeflowuniverse/herolib/releases/latest'
	resp := http.get(url)!
	release := json.decode[GithubRelease](resp.body) or {
		return error('Failed to decode GitHub response: ${err}')
	}
	return release.tag_name
}

// Show current version
latest_release := get_latest_release() or {
	eprintln('Error getting latest release: ${err}')
	exit(1)
}
println('Current latest release: ${latest_release}')

// Ask for new version
new_version := os.input('Enter new version (e.g., 1.0.4): ')

// Validate version format
version_re := regex.regex_opt(r'^[0-9]+\.[0-9]+\.[0-9]+$') or {
	eprintln('Error creating regex: ${err}')
	exit(1)
}
if !version_re.matches_string(new_version) {
	eprintln('Error: Version must be in format X.Y.Z (e.g., 1.0.4)')
	exit(1)
}

ourdir := dir(@FILE)

os.chdir(ourdir)!
hero_v_path := '${ourdir}/cli/hero.v'

// Read hero.v
content := os.read_file(hero_v_path) or {
	eprintln('Error reading ${hero_v_path}: ${err}')
	exit(1)
}

// Find version line
mut version_line_idx := -1
mut lines := content.split_into_lines()
for i, line in lines {
	if line.contains('version:') {
		version_line_idx = i
		break
	}
}
if version_line_idx == -1 {
	eprintln('Error: Could not find version line in ${hero_v_path}')
	exit(1)
}

// Get indentation
old_line := lines[version_line_idx]
indent := old_line.all_before('version:')

// Create backup
os.cp(hero_v_path, '${hero_v_path}.backup') or {
	eprintln('Error creating backup: ${err}')
	exit(1)
}

// Replace version line
lines[version_line_idx] = '		version:     \'${new_version}\''

// Write back to file
os.write_file(hero_v_path, lines.join_lines()) or {
	eprintln('Error writing to ${hero_v_path}: ${err}')
	// Restore backup
	os.cp('${hero_v_path}.backup', hero_v_path) or { eprintln('Error restoring backup: ${err}') }
	exit(1)
}

// Clean up backup
os.rm('${hero_v_path}.backup') or { eprintln('Warning: Could not remove backup file: ${err}') }

// Update version in install_hero.sh
install_hero_path := '${ourdir}/install_hero.sh'
install_hero_content := os.read_file(install_hero_path) or {
	eprintln('Error reading ${install_hero_path}: ${err}')
	exit(1)
}

// Create backup of install_hero.sh
os.cp(install_hero_path, '${install_hero_path}.backup') or {
	eprintln('Error creating backup of install_hero.sh: ${err}')
	exit(1)
}

// Replace version in install_hero.sh
mut install_hero_lines := install_hero_content.split_into_lines()
for i, line in install_hero_lines {
	if line.contains("version='") {
		install_hero_lines[i] = "version='${new_version}'"
		break
	}
}

// Write back to install_hero.sh
os.write_file(install_hero_path, install_hero_lines.join_lines()) or {
	eprintln('Error writing to ${install_hero_path}: ${err}')
	// Restore backup
	os.cp('${install_hero_path}.backup', install_hero_path) or {
		eprintln('Error restoring backup of install_hero.sh: ${err}')
	}
	exit(1)
}

// Clean up backup of install_hero.sh
os.rm('${install_hero_path}.backup') or {
	eprintln('Warning: Could not remove backup file of install_hero.sh: ${err}')
}

cmd := '
git add . -A
git commit -am "bump version to ${new_version}"
git push
git checkout development
git pull origin development
git push
git remote set-url origin git@github.com:freeflowuniverse/herolib.git
git add ${hero_v_path} ${install_hero_path}
git commit -m "bump version to ${new_version}"
git pull git@github.com:freeflowuniverse/herolib.git main
git tag -a "v${new_version}" -m "Release version ${new_version}"
git push git@github.com:freeflowuniverse/herolib.git "v${new_version}"
'

println(cmd)

os.execute_or_panic('${cmd}')

println('Release v${new_version} created and pushed!')
