#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.builder
import incubaid.herolib.core.pathlib

// Configuration for the remote builder
// Update these values for your remote machine
const remote_host = 'root@65.109.31.171' // Change to your remote host

const remote_port = 22 // SSH port

// Build configuration
const build_dir = '/root/zosbuilder'
const repo_url = 'https://git.ourworld.tf/tfgrid/zosbuilder'

// Optional: Set to true to upload kernel to S3
const upload_kernel = false

fn main() {
	println('=== Zero OS Builder - Remote Build System ===\n')

	// Initialize builder
	mut b := builder.new() or {
		eprintln('Failed to initialize builder: ${err}')
		exit(1)
	}

	// Connect to remote node
	println('Connecting to remote builder: ${remote_host}:${remote_port}')
	mut node := b.node_new(
		ipaddr: '${remote_host}:${remote_port}'
		name:   'zosbuilder'
	) or {
		eprintln('Failed to connect to remote node: ${err}')
		exit(1)
	}

	// Run the build process
	build_zos(mut node) or {
		eprintln('Build failed: ${err}')
		exit(1)
	}

	println('\n=== Build completed successfully! ===')
}

fn build_zos(mut node builder.Node) ! {
	println('\n--- Step 1: Installing prerequisites ---')
	install_prerequisites(mut node)!

	println('\n--- Step 2: Cloning zosbuilder repository ---')
	clone_repository(mut node)!

	println('\n--- Step 3: Creating RFS configuration ---')
	create_rfs_config(mut node)!

	println('\n--- Step 4: Running build ---')
	run_build(mut node)!

	println('\n--- Step 5: Checking build artifacts ---')
	check_artifacts(mut node)!

	println('\n=== Build completed successfully! ===')
}

fn install_prerequisites(mut node builder.Node) ! {
	println('Detecting platform...')

	// Check platform type
	if node.platform == .ubuntu {
		println('Installing Ubuntu/Debian prerequisites...')

		// Update package list and install all required packages
		node.exec_cmd(
			cmd:   '
				apt-get update
				apt-get install -y \\
					build-essential \\
					upx-ucl \\
					binutils \\
					git \\
					wget \\
					curl \\
					qemu-system-x86 \\
					podman \\
					musl-tools \\
					cpio \\
					xz-utils \\
					bc \\
					flex \\
					bison \\
					libelf-dev \\
					libssl-dev
				
				# Install rustup and Rust toolchain
				if ! command -v rustup &> /dev/null; then
					echo "Installing rustup..."
					curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
					source "\$HOME/.cargo/env"
				fi
				
				# Add Rust musl target
				source "\$HOME/.cargo/env"
				rustup target add x86_64-unknown-linux-musl
			'
			name:  'install_ubuntu_packages'
			reset: true
		)!
	} else if node.platform == .alpine {
		println('Installing Alpine prerequisites...')

		node.exec_cmd(
			cmd:   '
				apk add --no-cache \\
					build-base \\
					rust \\
					cargo \\
					upx \\
					git \\
					wget \\
					qemu-system-x86 \\
					podman
				
				# Add Rust musl target
				rustup target add x86_64-unknown-linux-musl || echo "rustup not available"
			'
			name:  'install_alpine_packages'
			reset: true
		)!
	} else {
		return error('Unsupported platform: ${node.platform}. Only Ubuntu/Debian and Alpine are supported.')
	}

	println('Prerequisites installed successfully')
}

fn clone_repository(mut node builder.Node) ! {
	// Clean up disk space first
	println('Cleaning up disk space...')
	node.exec_cmd(
		cmd:    '
			# Remove old build directories if they exist
			rm -rf ${build_dir} || true
			
			# Clean up podman/docker cache to free space
			podman system prune -af || true
			
			# Clean up package manager cache
			if command -v apt-get &> /dev/null; then
				apt-get clean || true
			fi
			
			# Show disk space
			df -h /
		'
		name:   'cleanup_disk_space'
		stdout: true
	)!

	// Clone the repository
	println('Cloning from ${repo_url}...')
	node.exec_cmd(
		cmd:    '
			git clone ${repo_url} ${build_dir}
			cd ${build_dir}
			git log -1 --oneline
		'
		name:   'clone_zosbuilder'
		stdout: true
	)!

	println('Repository cloned successfully')
}

fn create_rfs_config(mut node builder.Node) ! {
	println('Creating config/rfs.conf...')

	rfs_config := 'S3_ENDPOINT="http://wizenoze.grid.tf:3900"
S3_REGION="garage"
S3_BUCKET="zos"
S3_PREFIX="store"
S3_ACCESS_KEY="<put key here>"
S3_SECRET_KEY="<put key here>"
WEB_ENDPOINT=""
MANIFESTS_SUBPATH="flists"
READ_ACCESS_KEY="<put key here>"
READ_SECRET_KEY="<put key here>"
ROUTE_ENDPOINT="http://wizenoze.grid.tf:3900"
ROUTE_PATH="/zos/store"
ROUTE_REGION="garage"
KEEP_S3_FALLBACK="false"
UPLOAD_MANIFESTS="true"
'

	// Create config directory if it doesn't exist
	node.exec_cmd(
		cmd:    'mkdir -p ${build_dir}/config'
		name:   'create_config_dir'
		stdout: false
	)!

	// Write the RFS configuration file
	node.file_write('${build_dir}/config/rfs.conf', rfs_config)!

	// Verify the file was created
	result := node.exec(
		cmd:    'cat ${build_dir}/config/rfs.conf'
		stdout: false
	)!

	println('RFS configuration created successfully')
	println('Config preview:')
	println(result)

	// Skip youki component by removing it from sources.conf
	println('\nRemoving youki from sources.conf (requires SSH keys)...')
	node.exec_cmd(
		cmd:    '
			# Remove any line containing youki from sources.conf
			grep -v "youki" ${build_dir}/config/sources.conf > ${build_dir}/config/sources.conf.tmp
			mv ${build_dir}/config/sources.conf.tmp ${build_dir}/config/sources.conf
			
			# Verify it was removed
			echo "Updated sources.conf:"
			cat ${build_dir}/config/sources.conf
		'
		name:   'remove_youki'
		stdout: true
	)!
	println('youki component skipped')
}

fn run_build(mut node builder.Node) ! {
	println('Starting build process...')
	println('This may take 15-30 minutes depending on your system...')
	println('Status updates will be printed every 2 minutes...\n')

	// Check disk space before building
	println('Checking disk space...')
	disk_info := node.exec(
		cmd:    'df -h ${build_dir}'
		stdout: false
	)!
	println(disk_info)

	// Clean up any previous build artifacts and corrupted databases
	println('Cleaning up previous build artifacts...')
	node.exec_cmd(
		cmd:    '
			cd ${build_dir}
			
			# Remove dist directory to clean up any corrupted databases
			rm -rf dist/
			
			# Clean up any temporary files
			rm -rf /tmp/rfs-* || true
			
			# Show available disk space after cleanup
			df -h ${build_dir}
		'
		name:   'cleanup_before_build'
		stdout: true
	)!

	// Make scripts executable and run build with periodic status messages
	mut build_cmd := '
		cd ${build_dir}
		
		# Source Rust environment
		source "\$HOME/.cargo/env"
		
		# Make scripts executable
		chmod +x scripts/build.sh scripts/clean.sh
		
		# Set environment variables
		export UPLOAD_KERNEL=${upload_kernel}
		export UPLOAD_MANIFESTS=false
		
		# Create a wrapper script that prints status every 2 minutes
		cat > /tmp/build_with_status.sh << "EOF"
#!/bin/bash
set -e

# Source Rust environment
source "\$HOME/.cargo/env"

# Start the build in background
./scripts/build.sh &
BUILD_PID=\$!

# Print status every 2 minutes while build is running
COUNTER=0
while kill -0 \$BUILD_PID 2>/dev/null; do
    sleep 120
    COUNTER=\$((COUNTER + 2))
    echo ""
    echo "=== Build still in progress... (\${COUNTER} minutes elapsed) ==="
    echo ""
done

# Wait for build to complete and get exit code
wait \$BUILD_PID
EXIT_CODE=\$?

if [ \$EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=== Build completed successfully after \${COUNTER} minutes ==="
else
    echo ""
    echo "=== Build failed after \${COUNTER} minutes with exit code \$EXIT_CODE ==="
fi

exit \$EXIT_CODE
EOF
		
		chmod +x /tmp/build_with_status.sh
		/tmp/build_with_status.sh
	' // Execute build with output

	result := node.exec_cmd(
		cmd:    build_cmd
		name:   'zos_build'
		stdout: true
		reset:  true
		period: 0 // Don't cache, always rebuild
	)!

	println('\nBuild completed!')
	println(result)
}

fn check_artifacts(mut node builder.Node) ! {
	println('Checking build artifacts in ${build_dir}/dist/...')

	// List the dist directory
	result := node.exec(
		cmd:    'ls -lh ${build_dir}/dist/'
		stdout: true
	)!

	println('\nBuild artifacts:')
	println(result)

	// Check for expected files
	vmlinuz_exists := node.file_exists('${build_dir}/dist/vmlinuz.efi')
	initramfs_exists := node.file_exists('${build_dir}/dist/initramfs.cpio.xz')

	if vmlinuz_exists && initramfs_exists {
		println('\n✓ Build artifacts created successfully:')
		println('  - vmlinuz.efi (Kernel with embedded initramfs)')
		println('  - initramfs.cpio.xz (Standalone initramfs archive)')

		// Get file sizes
		size_info := node.exec(
			cmd:    'du -h ${build_dir}/dist/vmlinuz.efi ${build_dir}/dist/initramfs.cpio.xz'
			stdout: false
		)!
		println('\nFile sizes:')
		println(size_info)
	} else {
		return error('Build artifacts not found. Build may have failed.')
	}
}

// Download artifacts to local machine
fn download_artifacts(mut node builder.Node, local_dest string) ! {
	println('Downloading artifacts to local machine...')

	mut dest_path := pathlib.get_dir(path: local_dest, create: true)!

	println('Downloading to ${dest_path.path}...')

	// Download the entire dist directory
	node.download(
		source: '${build_dir}/dist/'
		dest:   dest_path.path
	)!

	println('\n✓ Artifacts downloaded successfully to ${dest_path.path}')

	// List downloaded files
	println('\nDownloaded files:')
	result := node.exec(
		cmd:    'ls -lh ${dest_path.path}'
		stdout: false
	) or {
		println('Could not list local files')
		return
	}
	println(result)
}
