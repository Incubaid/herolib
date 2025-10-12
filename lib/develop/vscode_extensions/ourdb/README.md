# OurDB Viewer VSCode Extension

A Visual Studio Code extension for viewing OurDB files line by line. This extension provides a simple way to inspect the contents of .ourdb files directly in VSCode.

## Features

- Displays OurDB records with detailed information
- Shows record IDs, sizes, and content
- Formats JSON data for better readability
- Provides file metadata (size, modification date)
- Automatic file format detection for .ourdb files
- Custom editor for binary .ourdb files
- Context menu integration for .ourdb files
- File system watcher for automatic updates
- Refresh command to update the view

## Installation

//TODO: needs to be added to hero cmd line in installers

```
#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.develop.vscode_extensions.ourdb

// This example shows how to use the ourdb module to install or uninstall the VSCode extension

// Install the extension
ourdb.install_extension() or {
 eprintln('Failed to install extension: ${err}')
 exit(1)
}

// To uninstall, uncomment the following lines:
/*
ourdb.uninstall_extension() or {
 eprintln('Failed to uninstall extension: ${err}')
 exit(1)
}


```

3. Restart VSCode

### Manual Installation

If the scripts don't work, you can install manually:

1. Copy this extension folder to your VSCode extensions directory:
   - Windows: `%USERPROFILE%\.vscode\extensions\local-herolib.ourdb-viewer-0.0.1`
   - macOS: `~/.vscode/extensions/local-herolib.ourdb-viewer-0.0.1`
   - Linux: `~/.vscode/extensions/local-herolib.ourdb-viewer-0.0.1`

2. Restart VSCode

3. Verify installation:
   - Open the Command Palette (Ctrl+Shift+P or Cmd+Shift+P)
   - Type "Extensions: Show Installed Extensions"
   - You should see "OurDB Viewer" in the list

## Usage

1. Open any .ourdb file in VSCode
   - The extension will automatically detect .ourdb files and open them in the custom editor
   - If a file is detected as binary, you can right-click it in the Explorer and select "OurDB: Open File"

2. View the formatted contents:
   - File metadata (path, size, modification date)
   - Each record with its ID, size, and content
   - JSON data is automatically formatted for better readability

3. Update the view:
   - The view automatically updates when the file changes
   - Use the "OurDB: Refresh View" command from the command palette to manually refresh

## Troubleshooting

If the extension doesn't activate when opening .ourdb files:

1. Check that the extension is properly installed (see verification step above)
2. Try running the "Developer: Reload Window" command
3. Check the Output panel (View > Output) and select "OurDB Viewer" from the dropdown to see logs and error messages

### Viewing Extension Logs

The extension creates a dedicated output channel for logging:

1. Open the Output panel in VSCode (View > Output)
2. Select "OurDB Viewer" from the dropdown menu at the top right of the Output panel
3. You'll see detailed logs about the extension's activity, including file processing and any errors

If you don't see "OurDB Viewer" in the dropdown, try:

- Restarting VSCode
- Opening an .ourdb file (which should activate the extension)
- Reinstalling the extension using the provided installation scripts

### Working with Binary Files

If VSCode detects your .ourdb file as binary and doesn't automatically open it with the OurDB Viewer:

1. Right-click the file in the Explorer panel
2. Select "OurDB: Open File" from the context menu
3. The file will open in the custom OurDB Viewer

The extension now includes a custom editor that can handle binary .ourdb files directly, without needing to convert them to text first.

## File Format

This extension reads OurDB files according to the following format:

- 2 bytes: Data size (little-endian)
- 4 bytes: CRC32 checksum
- 6 bytes: Previous record location
- N bytes: Actual data

## Development

To modify or enhance this extension:

1. Make your changes to `extension.js` or `package.json`
2. Test by running the extension in a new VSCode window:
   - Press F5 in VSCode with this extension folder open
   - This will launch a new "Extension Development Host" window
   - Open an .ourdb file in the development window to test

3. Package using `vsce package` if you want to create a VSIX file:

   ```
   npm install -g @vscode/vsce
   vsce package
   ```

## License

This extension is part of the HeroLib project and follows its licensing terms.
