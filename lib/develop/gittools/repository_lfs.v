module gittools

import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core
import incubaid.herolib.osal.core as osal
import os

const binary_extensions = ['.pdf', '.docx', '.xlsx', '.pptx', '.zip', '.tar', '.gz', '.jpg', '.jpeg',
	'.png', '.gif', '.bmp', '.tiff', '.ico', '.webp', '.mp4', '.mp3', '.avi', '.mov', '.wmv', '.flv',
	'.mkv', '.wav', '.exe', '.dll', '.so', '.dylib', '.bin', '.dat', '.iso']

// check if repo has lfs enabled
pub fn (mut repo GitRepo) lfs_check() ! {
	repo.init()!

	// Get list of all files in the repository
	files_result := repo.exec('ls-files')!
	files := files_result.split('\n').filter(it.trim_space() != '')

	// Binary file extensions that should use LFS

	mut needs_lfs := false
	mut large_files := []string{}

	for file in files {
		file_path := '${repo.path()}/${file}'

		// Check if file exists (might be deleted)
		if !os.exists(file_path) {
			continue
		}

		// Check if file is in bin/ folder
		if file.starts_with('bin/') {
			needs_lfs = true
			large_files << file
			continue
		}

		// Check if file has binary extension
		for ext in binary_extensions {
			if file.to_lower().ends_with(ext) {
				needs_lfs = true
				large_files << file
				break
			}
		}

		// Check file size (files > 50MB should use LFS)
		file_info := os.stat(file_path) or { continue }
		size_mb := file_info.size / (1024 * 1024)
		if size_mb > 50 {
			needs_lfs = true
			large_files << '${file} (${size_mb}MB)'
		}
	}

	if needs_lfs {
		console.print_header('Repository contains files that should use Git LFS:')
		for file in large_files {
			console.print_item(file)
		}

		if !repo.lfs()! {
			console.print_stderr('Git LFS is not initialized. Run lfs_init() to set it up.')
		}
	} else {
		console.print_green('No large binary files detected. Git LFS may not be needed.')
	}
}

pub fn (mut repo GitRepo) lfs_init() ! {
	repo.init()!

	// Step 1: Check if git-lfs is installed on the system
	if !osal.cmd_exists('git-lfs') {
		console.print_header('Git LFS not found. Installing...')

		// Install based on platform
		platform := core.platform()!
		match platform {
			.osx {
				// Use brew on macOS
				if osal.cmd_exists('brew') {
					osal.execute_stdout('brew install git-lfs')!
				} else {
					return error('Homebrew not found. Please install git-lfs manually: https://git-lfs.github.com')
				}
			}
			.ubuntu {
				osal.execute_stdout('sudo apt-get update && sudo apt-get install -y git-lfs')!
			}
			.arch {
				osal.execute_stdout('sudo pacman -S git-lfs')!
			}
			else {
				return error('Unsupported platform. Please install git-lfs manually: https://git-lfs.github.com')
			}
		}

		console.print_green('Git LFS installed successfully.')
	}

	// Step 2: Initialize git-lfs in the repository
	console.print_header('Initializing Git LFS in repository...')
	repo.exec('lfs install --local')!

	console.print_header('Tracking binary file extensions...')
	for ext in binary_extensions {
		repo.exec('lfs track "*${ext}"') or {
			console.print_debug('Could not track ${ext}: ${err}')
			continue
		}
		console.print_item('Tracking *${ext}')
	}

	// Step 4: Track files in bin/ folders
	console.print_header('Tracking bin/ folders...')
	repo.exec('lfs track "bin/**"') or { console.print_debug('Could not track bin/**: ${err}') }

	// Step 5: Create and install pre-commit hook
	mut check_script := '
        #!/bin/bash
        # Prevent committing large files without LFS

        max_size=50 # MB
        files=$(git diff --cached --name-only)

        for file in \${files}; do
            if [ -f "\${file}" ]; then
                size=$(du -m "\${file}" | cut -f1)
                if [ "\${size}" -gt "\${max_size}" ]; then
                    if ! git check-attr filter -- "\${file}" | grep -q "lfs"; then
                        echo "❌ ERROR: \${file} is \${size}MB and not tracked by LFS."
                        echo "Please run: git lfs track \\"\${file}\\""
                        exit 1
                    fi
                fi
            fi
        done
    '
	check_script = texttools.dedent(check_script)

	hook_path := '${repo.path()}/.git/hooks/pre-commit'
	hooks_dir := '${repo.path()}/.git/hooks'

	// Ensure hooks directory exists
	osal.dir_ensure(hooks_dir)!

	// Write the pre-commit hook
	osal.file_write(hook_path, check_script)!

	// Make the hook executable
	osal.exec(cmd: 'chmod +x ${hook_path}')!

	console.print_green('Pre-commit hook installed at ${hook_path}')

	// Step 6: Add .gitattributes to the repository
	gitattributes_path := '${repo.path()}/.gitattributes'
	if os.exists(gitattributes_path) {
		console.print_debug('.gitattributes already exists, LFS tracks have been added to it.')
	} else {
		console.print_debug('.gitattributes created with LFS tracking rules.')
	}

	repo.commit('chore: Initialize Git LFS and track binary files')!
	repo.push()!

	// Step 7: Verify LFS is properly configured
	if !repo.lfs()! {
		return error('Git LFS initialization failed verification')
	}

	console.print_green('Git LFS initialized successfully for ${repo.name}')
	console.print_header('Next steps:')
}

// Check if repo has lfs enabled
pub fn (mut repo GitRepo) lfs() !bool {
	repo.init()!

	// Check if .git/hooks/pre-commit exists and contains LFS check
	hook_path := '${repo.path()}/.git/hooks/pre-commit'
	if !os.exists(hook_path) {
		return false
	}

	// Check if git lfs is initialized locally
	// This checks if .git/config contains lfs filter configuration
	config_result := repo.exec('config --local --get filter.lfs.clean') or { return false }

	return config_result.contains('git-lfs clean')
}
