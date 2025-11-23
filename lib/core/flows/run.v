module flows

import time as ostime

// Run the entire flow starting from current_step
pub fn (mut c Coordinator) run() ! {
	mut s := c.step_current()!
	c.run_step(mut s)!
}

// Run a single step, including error and next steps
pub fn (mut c Coordinator) run_step(mut step Step) ! {
	// Initialize step
	step.status = .running
	step.started_at = ostime.now().unix_milli()
	step.store_redis()!

	// Log step start
	step.log(
		level:   .info
		message: 'Step "${step.name}" started'
	)!

	// Execute main step function
	step.main_step(mut step) or {
		// Handle error
		step.status = .error
		step.error_msg = err.msg()
		step.finished_at = ostime.now().unix_milli()
		step.store_redis()!

		step.log(
			level:   .error
			message: 'Step "${step.name}" failed: ${err.msg()}'
		)!

		// Run error steps if any
		if step.error_steps.len > 0 {
			for mut error_step in step.error_steps {
				c.run_step(mut error_step)!
			}
		}

		return err
	}

	// Mark as success
	step.status = .success
	step.finished_at = ostime.now().unix_milli()
	step.store_redis()!

	step.log(
		level:   .info
		message: 'Step "${step.name}" completed successfully'
	)!

	// Run next steps if any
	if step.next_steps.len > 0 {
		for mut next_step in step.next_steps {
			c.run_step(mut next_step)!
		}
	}
}

// Get step state from redis
pub fn (c Coordinator) get_step_state(step_name string) !map[string]string {
	if redis := c.redis {
		return redis.hgetall('flow:${c.name}:${step_name}')!
	}
	return error('Redis not configured')
}

// Get all steps state from redis (for UI dashboard)
pub fn (c Coordinator) get_all_steps_state() ![]map[string]string {
	mut states := []map[string]string{}
	if redis := c.redis {
		pattern := 'flow:${c.name}:*'
		keys := redis.keys(pattern)!
		for key in keys {
			state := redis.hgetall(key)!
			states << state
		}
	}
	return states
}

pub fn (c Coordinator) clear_redis() ! {
	if redis := c.redis {
		pattern := 'flow:${c.name}:*'
		keys := redis.keys(pattern)!
		for key in keys {
			redis.del(key)!
		}
	}
}
