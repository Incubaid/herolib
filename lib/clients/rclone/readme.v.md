# RCloneClient Module

This module provides a V language interface to RCloneClient, a command line program to manage files on cloud storage.

## Features

- Mount/unmount remote storage
- Upload files and directories
- Download files and directories
- List remote contents
- Configuration management through heroscript format

## Prerequisites

RCloneClient must be installed on your system. Visit <https://rclone.org/install/> for installation instructions.

## Usage

```v
import incubaid.herolib.osal.core.rclone

fn main() {
    // Create a new RCloneClient instance
    mut rc := rclone.new('my_remote') or { panic(err) }

    // Upload a directory
    rc.upload('./local_dir', 'backup/remote_dir') or { panic(err) }

    // Download a directory
    rc.download('backup/remote_dir', './downloaded_dir') or { panic(err) }

    // Mount a remote
    rc.mount('backup', './mounted_backup') or { panic(err) }

    // List contents
    content := rc.list('backup') or { panic(err) }
    println(content)

    // Unmount when done
    rc.unmount('./mounted_backup') or { panic(err) }
}
```

## Configuration

Configuration is managed through heroscript format in `~/hero/config`. Example configuration:

```heroscript
!!config.s3server_define
    name:'my_remote'
    description:'My Remote Storage'
    keyid:'your_key_id'
    keyname:'your_key_name'
    appkey:'your_app_key'
    url:'your_url'
```

The configuration will be automatically loaded and applied when creating a new RCloneClient instance.

## Testing

To run the tests:

```bash
vtest ~/code/github/incubaid/herolib/lib/osal/rclone/rclone_test.v
```

Note: Some tests are commented out as they require an actual rclone configuration and remote to work with. They serve as examples of how to use the RCloneClient module.
