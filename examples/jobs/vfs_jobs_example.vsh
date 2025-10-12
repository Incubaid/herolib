#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.jobs.model
import flag
import os
import time

// This example demonstrates using the VFS-based job storage
// - Creating jobs and storing them in VFS
// - Listing jobs from VFS
// - Cleaning up old jobs

mut fp := flag.new_flag_parser(os.args)
fp.application('vfs_jobs_example.vsh')
fp.version('v0.1.0')
fp.description('Example of VFS-based job storage with cleanup functionality')
fp.skip_executable()

cleanup_days := fp.int('days', `d`, 7, 'Clean up jobs older than this many days')
create_count := fp.int('create', `c`, 5, 'Number of jobs to create')
help_requested := fp.bool('help', `h`, false, 'Show help message')

if help_requested {
	println(fp.usage())
	exit(0)
}

additional_args := fp.finalize() or {
	eprintln(err)
	println(fp.usage())
	exit(1)
}

// Create a new HeroRunner instance
mut runner := model.new() or { panic('Failed to create HeroRunner: ${err}') }

println('\n---------BEGIN VFS JOBS EXAMPLE')

// Create some jobs
println('\n---------CREATING JOBS')
for i in 0 .. create_count {
	mut job := runner.jobs.new()
	job.guid = 'job_${i}_${time.now().unix}'
	job.actor = 'example_actor'
	job.action = 'test_action'
	job.params = {
		'param1': 'value1'
		'param2': 'value2'
	}

	// For demonstration, make some jobs older by adjusting their creation time
	if i % 2 == 0 {
		job.status.created.time = time.now().add_days(-(cleanup_days + 1))
	}

	runner.jobs.set(job) or { panic('Failed to set job: ${err}') }
	println('Created job with GUID: ${job.guid}')
}

// List all jobs
println('\n---------LISTING ALL JOBS')
jobs := runner.jobs.list() or { panic('Failed to list jobs: ${err}') }
println('Found ${jobs.len} jobs:')
for job in jobs {
	days_ago := (time.now().unix - job.status.created.time.unix) / (60 * 60 * 24)
	println('- ${job.guid} (created ${days_ago} days ago)')
}

// Clean up old jobs
println('\n---------CLEANING UP OLD JOBS')
println('Cleaning up jobs older than ${cleanup_days} days...')
deleted_count := runner.cleanup_jobs(cleanup_days) or { panic('Failed to clean up jobs: ${err}') }
println('Deleted ${deleted_count} old jobs')

// List remaining jobs
println('\n---------LISTING REMAINING JOBS')
remaining_jobs := runner.jobs.list() or { panic('Failed to list jobs: ${err}') }
println('Found ${remaining_jobs.len} remaining jobs:')
for job in remaining_jobs {
	days_ago := (time.now().unix - job.status.created.time.unix) / (60 * 60 * 24)
	println('- ${job.guid} (created ${days_ago} days ago)')
}

println('\n---------END VFS JOBS EXAMPLE')
