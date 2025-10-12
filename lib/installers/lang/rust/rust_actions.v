module rust

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.core
import incubaid.herolib.installers.base
import incubaid.herolib.installers.ulist
import os

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()!} rustc -V')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse rust version.\n${res.output}")
	}
	myversion := r[0].all_after_first('rustc').all_before('(')
	if texttools.version(version) == texttools.version(myversion) {
		return true
	}
	return false
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {
	// installers.upload(
	//     cmdname: 'rust'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/rust'
	// )!
}

fn install() ! {
	console.print_header('install rust')
	base.install()!

	pl := core.platform()!

	if pl == .ubuntu {
		osal.package_install('build-essential,openssl,pkg-config,libssl-dev,gcc')!
	}
	if pl == .arch {
		osal.package_install('rust, cargo, pkg-config, openssl')!
		return
	} else {
		osal.execute_stdout("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y")!
	}

	osal.profile_path_add_remove(paths2add: '${os.home_dir()}/.cargo/bin')!
	console.print_header('rust is installed')
}

fn destroy() ! {
	pl := core.platform()!
	if pl == .arch {
		osal.package_remove('rust')!
	}

	osal.exec(
		cmd:   '
        #!/bin/bash

        # Script to uninstall Rust and Rust-related files
        # Use at your own risk. Make sure to backup your data if necessary.

        echo "Starting Rust uninstallation process..."

        # Step 1: Check if rustup is installed
        if command -v rustup > /dev/null 2>&1; then
            echo "Rustup found. Proceeding with uninstallation."
            rustup self uninstall -y
        else
            echo "Rustup is not installed. Skipping rustup uninstallation."
        fi

        # Step 2: Remove cargo and rustc binaries
        echo "Removing cargo and rustc binaries if they exist..."
        rm -f ~/.cargo/bin/cargo
        rm -f ~/.cargo/bin/rustc

        # Step 3: Remove Rust-related directories
        echo "Removing Rust-related directories..."
        rm -rf ~/.cargo
        rm -rf ~/.rustup

        echo "Rust uninstallation process completed."

    '
		debug: false
	)!

	osal.rm('
        rustc
        rustup
        cargo
        ')!
}
