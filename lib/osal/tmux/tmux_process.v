module tmux

pub struct ProcessStats {
pub mut:
	cpu_percent    f64
	memory_bytes   u64
	memory_percent f64
}

enum ProcessStatus {
	running
	finished_ok
	finished_error
	not_found
}
