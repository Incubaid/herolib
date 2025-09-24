module tmux

import freeflowuniverse.herolib.osal.core as osal
import crypto.md5
import json
import time
import freeflowuniverse.herolib.ui.console

// Command state structure for Redis storage
pub struct CommandState {
pub mut:
	cmd_md5    string // MD5 hash of the command
	cmd_text   string // Original command text
	status     string // running|finished|failed|unknown
	pid        int    // Process ID of the command
	started_at string // Timestamp when command started
	last_check string // Last time status was checked
	pane_id    int    // Pane ID for reference
}

// Generate Redis key for command state tracking
// Pattern: herotmux:${session}:${window}|${pane}
pub fn (p &Pane) get_state_key() string {
	return 'herotmux:${p.window.session.name}:${p.window.name}|${p.id}'
}

// Generate MD5 hash for a command (normalized)
pub fn normalize_and_hash_command(cmd string) string {
	// Normalize command: trim whitespace, normalize newlines
	normalized := cmd.trim_space().replace('\r\n', '\n').replace('\r', '\n')
	return md5.hexhash(normalized)
}

// Store command state in Redis
pub fn (mut p Pane) store_command_state(cmd string, status string, pid int) ! {
	key := p.get_state_key()
	cmd_hash := normalize_and_hash_command(cmd)
	now := time.now().format_ss_milli()

	state := CommandState{
		cmd_md5:    cmd_hash
		cmd_text:   cmd
		status:     status
		pid:        pid
		started_at: now
		last_check: now
		pane_id:    p.id
	}

	state_json := json.encode(state)
	p.window.session.tmux.redis.set(key, state_json)!

	console.print_debug('Stored command state for pane ${p.id}: ${cmd_hash[..8]}... status=${status}')
}

// Retrieve command state from Redis
pub fn (mut p Pane) get_command_state() ?CommandState {
	key := p.get_state_key()
	state_json := p.window.session.tmux.redis.get(key) or { return none }

	if state_json.len == 0 {
		return none
	}

	state := json.decode(CommandState, state_json) or {
		console.print_debug('Failed to decode command state for pane ${p.id}: ${err}')
		return none
	}

	return state
}

// Check if command has changed by comparing MD5 hashes
pub fn (mut p Pane) has_command_changed(new_cmd string) bool {
	stored_state := p.get_command_state() or { return true }
	new_hash := normalize_and_hash_command(new_cmd)
	return stored_state.cmd_md5 != new_hash
}

// Update command status in Redis
pub fn (mut p Pane) update_command_status(status string) ! {
	mut stored_state := p.get_command_state() or { return }
	stored_state.status = status
	stored_state.last_check = time.now().format_ss_milli()

	key := p.get_state_key()
	state_json := json.encode(stored_state)
	p.window.session.tmux.redis.set(key, state_json)!

	console.print_debug('Updated command status for pane ${p.id}: ${status}')
}

// Clear command state from Redis (when pane is reset or command is removed)
pub fn (mut p Pane) clear_command_state() ! {
	key := p.get_state_key()
	p.window.session.tmux.redis.del(key) or {
		console.print_debug('Failed to clear command state for pane ${p.id}: ${err}')
	}
	console.print_debug('Cleared command state for pane ${p.id}')
}

// Check if stored command is currently running by verifying the PID
pub fn (mut p Pane) is_stored_command_running() bool {
	stored_state := p.get_command_state() or { return false }

	if stored_state.pid <= 0 {
		return false
	}

	// Use osal to check if process exists
	return osal.process_exists(stored_state.pid)
}

// Get all command states for a session (useful for debugging/monitoring)
pub fn (mut s Session) get_all_command_states() !map[string]CommandState {
	mut states := map[string]CommandState{}

	// Get all keys matching the session pattern
	pattern := 'herotmux:${s.name}:*'
	keys := s.tmux.redis.keys(pattern)!

	for key in keys {
		state_json := s.tmux.redis.get(key) or { continue }
		if state_json.len == 0 {
			continue
		}

		state := json.decode(CommandState, state_json) or {
			console.print_debug('Failed to decode state for key ${key}: ${err}')
			continue
		}

		states[key] = state
	}

	return states
}

// Clean up stale command states (for maintenance)
pub fn (mut s Session) cleanup_stale_command_states() ! {
	states := s.get_all_command_states()!

	for key, state in states {
		// Check if the process is still running
		if state.pid > 0 && !osal.process_exists(state.pid) {
			// Process is dead, update status
			mut updated_state := state
			updated_state.status = 'finished'
			updated_state.last_check = time.now().format_ss_milli()

			state_json := json.encode(updated_state)
			s.tmux.redis.set(key, state_json)!

			console.print_debug('Updated stale command state ${key}: process ${state.pid} no longer exists')
		}
	}
}
