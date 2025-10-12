module herorun2

import incubaid.herolib.ui.console

// Provider types
pub enum Provider {
	hetzner
	threefold
}

// Factory function to create appropriate backend
pub fn new_backend(provider Provider, args NewNodeArgs) !NodeBackend {
	match provider {
		.hetzner {
			console.print_header('🏭 Creating Hetzner Backend')
			backend := new_hetzner_backend(args)!
			return backend
		}
		.threefold {
			console.print_header('🏭 Creating ThreeFold Backend')
			// TODO: Implement ThreeFold backend
			return error('ThreeFold backend not implemented yet')
		}
	}
}

// Convenience function for Hetzner (most common case)
pub fn new_hetzner_node(args NewNodeArgs) !NodeBackend {
	return new_backend(.hetzner, args)!
}
