module crun

import json
import freeflowuniverse.herolib.core.pathlib

// Simple JSON generation using V's built-in json module
pub fn (config CrunConfig) to_json() !string {
	return json.encode_pretty(config.spec)
}

// Convenience method to save JSON to file
pub fn (config CrunConfig) save_to_file(path string) ! {
	json_content := config.to_json()!

	mut file := pathlib.get_file(path: path, create: true)!
	file.write(json_content)!
}

// Validate the configuration
pub fn (config CrunConfig) validate() ! {
	if config.spec.oci_version == '' {
		return error('ociVersion cannot be empty')
	}

	if config.spec.process.args.len == 0 {
		return error('process.args cannot be empty')
	}

	if config.spec.root.path == '' {
		return error('root.path cannot be empty')
	}

	// Validate that required capabilities are present
	required_caps := ['CAP_AUDIT_WRITE', 'CAP_KILL', 'CAP_NET_BIND_SERVICE']
	for cap in required_caps {
		if cap !in config.spec.process.capabilities.bounding {
			return error('missing required capability: ${cap}')
		}
	}
}
