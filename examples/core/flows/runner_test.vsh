#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.flows
import incubaid.herolib.core.redisclient
import incubaid.herolib.ui.console
import incubaid.herolib.data.ourtime
import time

fn main() {
	mut cons := console.new()

	console.print_header('Flow Runner Test Suite')
	console.print_lf(1)

	// Test 1: Basic Flow Execution
	console.print_item('Test 1: Basic Flow with Successful Steps')
	test_basic_flow()!
	console.print_lf(1)

	// Test 2: Error Handling
	console.print_item('Test 2: Error Handling with Error Steps')
	test_error_handling()!
	console.print_lf(1)

	// Test 3: Multiple Next Steps
	console.print_item('Test 3: Multiple Next Steps')
	test_multiple_next_steps()!
	console.print_lf(1)

	// Test 4: Redis State Retrieval
	console.print_item('Test 4: Redis State Retrieval and JSON')
	test_redis_state()!
	console.print_lf(1)

	// Test 5: Complex Flow Chain
	console.print_item('Test 5: Complex Flow Chain')
	test_complex_flow()!
	console.print_lf(1)

	console.print_header('All Tests Completed Successfully!')
}

fn test_basic_flow() ! {
	mut redis := redisclient.core_get()!
	redis.flushdb()!

	mut coordinator := flows.new(
		name: 'test_basic_flow',
		redis: redis,
		ai: none
	)!

	// Step 1: Initialize
	mut step1 := coordinator.step_new(
		name: 'initialize'
		description: 'Initialize test environment'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Step 1: Initializing...')
			s.context['init_time'] = ourtime.now().str()
		}
	)!

	// Step 2: Process
	mut step2 := coordinator.step_new(
		name: 'process'
		description: 'Process data'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Step 2: Processing...')
			s.context['processed'] = 'true'
		}
	)!

	// Step 3: Finalize
	mut step3 := coordinator.step_new(
		name: 'finalize'
		description: 'Finalize results'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Step 3: Finalizing...')
			s.context['status'] = 'completed'
		}
	)!

	step1.next_step_add(step2)
	step2.next_step_add(step3)

	coordinator.run()!

	// Verify Redis state
	state := coordinator.get_all_steps_state()!
	assert state.len >= 3, 'Expected at least 3 steps in Redis'

	for step_state in state {
		assert step_state['status'] == 'success', 'Expected all steps to be successful'
	}

	println('  ✓ Test 1 PASSED: All steps executed successfully')
	coordinator.clear_redis()!
}

fn test_error_handling() ! {
	mut redis := redisclient.core_get()!
	redis.flushdb()!

	mut coordinator := flows.new(
		name: 'test_error_flow',
		redis: redis,
		ai: none
	)!

	// Error step
	mut error_recovery := coordinator.step_new(
		name: 'error_recovery'
		description: 'Recover from error'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Error Step: Executing recovery...')
			s.context['recovered'] = 'true'
		}
	)!

	// Main step that fails
	mut main_step := coordinator.step_new(
		name: 'failing_step'
		description: 'This step will fail'
		f: fn (mut s flows.Step) ! {
			println('  ✗ Main Step: Intentionally failing...')
			return error('Simulated error for testing')
		}
	)!

	main_step.error_step_add(error_recovery)

	// Run and expect error
	coordinator.run() or {
		println('  ✓ Error caught as expected: ${err.msg()}')
	}

	// Verify error state in Redis
	error_state := coordinator.get_step_state('failing_step')!
	assert error_state['status'] == 'error', 'Expected step to be in error state'

	recovery_state := coordinator.get_step_state('error_recovery')!
	assert recovery_state['status'] == 'success', 'Expected error step to execute'

	println('  ✓ Test 2 PASSED: Error handling works correctly')
	coordinator.clear_redis()!
}

fn test_multiple_next_steps() ! {
	mut redis := redisclient.core_get()!
	redis.flushdb()!

	mut coordinator := flows.new(
		name: 'test_parallel_steps',
		redis: redis,
		ai: none
	)!

	// Parent step
	mut parent := coordinator.step_new(
		name: 'parent_step'
		description: 'Parent step with multiple children'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Parent Step: Executing...')
		}
	)!

	// Child steps
	mut child1 := coordinator.step_new(
		name: 'child_step_1'
		description: 'First child'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Child Step 1: Executing...')
		}
	)!

	mut child2 := coordinator.step_new(
		name: 'child_step_2'
		description: 'Second child'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Child Step 2: Executing...')
		}
	)!

	mut child3 := coordinator.step_new(
		name: 'child_step_3'
		description: 'Third child'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Child Step 3: Executing...')
		}
	)!

	// Add multiple next steps
	parent.next_step_add(child1)
	parent.next_step_add(child2)
	parent.next_step_add(child3)

	coordinator.run()!

	// Verify all steps executed
	all_states := coordinator.get_all_steps_state()!
	assert all_states.len >= 4, 'Expected 4 steps to execute'

	println('  ✓ Test 3 PASSED: Multiple next steps executed sequentially')
	coordinator.clear_redis()!
}

fn test_redis_state() ! {
	mut redis := redisclient.core_get()!
	redis.flushdb()!

	mut coordinator := flows.new(
		name: 'test_redis_state',
		redis: redis,
		ai: none
	)!

	mut step1 := coordinator.step_new(
		name: 'redis_test_step'
		description: 'Test Redis state storage'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Executing step with context...')
			s.context['user'] = 'test_user'
			s.context['action'] = 'test_action'
		}
	)!

	coordinator.run()!

	// Retrieve state from Redis
	step_state := coordinator.get_step_state('redis_test_step')!

	println('  Step state in Redis:')
	for key, value in step_state {
		println('    ${key}: ${value}')
	}

	// Verify fields
	assert step_state['name'] == 'redis_test_step', 'Step name mismatch'
	assert step_state['status'] == 'success', 'Step status should be success'
	assert step_state['description'] == 'Test Redis state storage', 'Description mismatch'

	// Verify JSON is stored
	if json_data := step_state['json'] {
		println('  ✓ JSON data stored in Redis: ${json_data[0..50]}...')
	}

	// Verify log count
	logs_count := step_state['logs_count'] or { '0' }
	println('  ✓ Logs count: ${logs_count}')

	println('  ✓ Test 4 PASSED: Redis state correctly stored and retrieved')
	coordinator.clear_redis()!
}

fn test_complex_flow() ! {
	mut redis := redisclient.core_get()!
	redis.flushdb()!

	mut coordinator := flows.new(
		name: 'test_complex_flow',
		redis: redis,
		ai: none
	)!

	// Step 1: Validate
	mut validate := coordinator.step_new(
		name: 'validate_input'
		description: 'Validate input parameters'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Validating input...')
			s.context['validated'] = 'true'
		}
	)!

	// Step 2: Transform (next step after validate)
	mut transform := coordinator.step_new(
		name: 'transform_data'
		description: 'Transform input data'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Transforming data...')
			s.context['transformed'] = 'true'
		}
	)!

	// Step 3a: Save to DB (next step after transform)
	mut save_db := coordinator.step_new(
		name: 'save_to_database'
		description: 'Save data to database'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Saving to database...')
			s.context['saved'] = 'true'
		}
	)!

	// Step 3b: Send notification (next step after transform)
	mut notify := coordinator.step_new(
		name: 'send_notification'
		description: 'Send notification'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Sending notification...')
			s.context['notified'] = 'true'
		}
	)!

	// Step 4: Cleanup (final step)
	mut cleanup := coordinator.step_new(
		name: 'cleanup'
		description: 'Cleanup resources'
		f: fn (mut s flows.Step) ! {
			println('  ✓ Cleaning up...')
			s.context['cleaned'] = 'true'
		}
	)!

	// Build the flow chain
	validate.next_step_add(transform)
	transform.next_step_add(save_db)
	transform.next_step_add(notify)
	save_db.next_step_add(cleanup)
	notify.next_step_add(cleanup)

	coordinator.run()!

	// Verify all steps executed
	all_states := coordinator.get_all_steps_state()!
	println('  Total steps executed: ${all_states.len}')

	for state in all_states {
		name := state['name'] or { 'unknown' }
		status := state['status'] or { 'unknown' }
		duration := state['duration'] or { '0' }
		println('    - ${name}: ${status} (${duration}ms)')
	}

	assert all_states.len >= 5, 'Expected at least 5 steps'

	println('  ✓ Test 5 PASSED: Complex flow executed successfully')
	coordinator.clear_redis()!
}