# Zero OS Builder - Remote Build System

This example demonstrates how to build [Zero OS (zosbuilder)](https://git.ourworld.tf/tfgrid/zosbuilder) on a remote machine using the herolib builder module.

## Overview

The zosbuilder creates a Zero OS Alpine Initramfs with:
- Alpine Linux 3.22 base
- Custom kernel with embedded initramfs
- ThreeFold components (zinit, rfs, mycelium, zosstorage)
- Optimized size with UPX compression
- Two-stage module loading

## Prerequisites

### Local Machine
- V compiler installed
- SSH access to a remote build machine
- herolib installed

### Remote Build Machine
The script will automatically install these on the remote machine:
- **Ubuntu/Debian**: build-essential, rustc, cargo, upx-ucl, binutils, git, wget, qemu-system-x86, podman, musl-tools
- **Alpine Linux**: build-base, rust, cargo, upx, git, wget, qemu-system-x86, podman
- Rust musl target (x86_64-unknown-linux-musl)

## Configuration

Edit the constants in `zosbuilder.vsh`:

```v
const (
    // Remote machine connection
    remote_host = 'root@195.192.213.2'  // Your remote host
    remote_port = 22                     // SSH port
    
    // Build configuration
    build_dir = '/root/zosbuilder'       // Build directory on remote
    repo_url = 'https://git.ourworld.tf/tfgrid/zosbuilder'
    
    // Optional: Upload kernel to S3
    upload_kernel = false
)
```

## Usage

### Basic Build

```bash
# Make the script executable
chmod +x zosbuilder.vsh

# Run the build
./zosbuilder.vsh
```

### What the Script Does

1. **Connects to Remote Machine**: Establishes SSH connection to the build server
2. **Installs Prerequisites**: Automatically installs all required build tools
3. **Clones Repository**: Fetches the latest zosbuilder code
4. **Runs Build**: Executes the build process (takes 15-30 minutes)
5. **Verifies Artifacts**: Checks that build outputs were created successfully

### Build Output

The build creates two main artifacts in `${build_dir}/dist/`:
- `vmlinuz.efi` - Kernel with embedded initramfs (bootable)
- `initramfs.cpio.xz` - Standalone initramfs archive

## Build Process Details

The zosbuilder follows these phases:

### Phase 1: Environment Setup
- Creates build directories
- Installs build dependencies
- Sets up Rust musl target

### Phase 2: Alpine Base
- Downloads Alpine 3.22 miniroot
- Extracts to initramfs directory
- Installs packages from config/packages.list

### Phase 3: Component Building
- Builds zinit (init system)
- Builds rfs (remote filesystem)
- Builds mycelium (networking)
- Builds zosstorage (storage orchestration)

### Phase 4: System Configuration
- Replaces /sbin/init with zinit
- Copies zinit configuration
- Sets up 2-stage module loading
- Configures system services

### Phase 5: Optimization
- Removes docs, man pages, locales
- Strips executables and libraries
- UPX compresses all binaries
- Aggressive cleanup

### Phase 6: Packaging
- Creates initramfs.cpio.xz with XZ compression
- Builds kernel with embedded initramfs
- Generates vmlinuz.efi
- Optionally uploads to S3

## Advanced Usage

### Download Artifacts to Local Machine

Add this to your script after the build completes:

```v
// Download artifacts to local machine
download_artifacts(mut node, '/tmp/zos-artifacts') or {
    eprintln('Failed to download artifacts: ${err}')
}
```

### Custom Build Configuration

You can modify the build by editing files on the remote machine before building:

```v
// After cloning, before building
node.file_write('${build_dir}/config/packages.list', 'your custom packages')!
```

### Rebuild Without Re-cloning

To rebuild without re-cloning the repository, modify the script to skip the clone step:

```v
// Comment out the clone_repository call
// clone_repository(mut node)!

// Or just run the build directly
node.exec_cmd(
    cmd: 'cd ${build_dir} && ./scripts/build.sh'
    name: 'zos_rebuild'
)!
```

## Testing the Build

After building, you can test the kernel with QEMU:

```bash
# On the remote machine
cd /root/zosbuilder
./scripts/test-qemu.sh
```

## Troubleshooting

### Build Fails

1. Check the build output for specific errors
2. Verify all prerequisites are installed
3. Ensure sufficient disk space (at least 5GB)
4. Check internet connectivity for downloading components

### SSH Connection Issues

1. Verify SSH access: `ssh root@195.192.213.2`
2. Check SSH key authentication is set up
3. Verify the remote host and port are correct

### Missing Dependencies

The script automatically installs dependencies, but if manual installation is needed:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y build-essential rustc cargo upx-ucl binutils git wget qemu-system-x86 podman musl-tools
rustup target add x86_64-unknown-linux-musl
```

**Alpine Linux:**
```bash
apk add --no-cache build-base rust cargo upx git wget qemu-system-x86 podman
rustup target add x86_64-unknown-linux-musl
```

## Integration with CI/CD

This builder can be integrated into CI/CD pipelines:

```v
// Example: Build and upload to artifact storage
fn ci_build() ! {
    mut b := builder.new()!
    mut node := b.node_new(ipaddr: '${ci_builder_host}')!
    
    build_zos(mut node)!
    
    // Upload to artifact storage
    node.exec_cmd(
        cmd: 's3cmd put ${build_dir}/dist/* s3://artifacts/zos/'
        name: 'upload_artifacts'
    )!
}
```

## Related Examples

- `simple.vsh` - Basic builder usage
- `remote_executor/` - Remote code execution
- `simple_ip4.vsh` - IPv4 connection example
- `simple_ip6.vsh` - IPv6 connection example

## References

- [zosbuilder Repository](https://git.ourworld.tf/tfgrid/zosbuilder)
- [herolib Builder Documentation](../../lib/builder/readme.md)
- [Zero OS Documentation](https://manual.grid.tf/)

## License

This example follows the same license as herolib.
