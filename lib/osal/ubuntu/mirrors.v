module ubuntu

import incubaid.herolib.osal.core as osal
import incubaid.herolib.core.texttools
import net.http
import os
import time
import net.urllib
import net
import sync

pub struct PerfResult {
pub mut:
	url     string
	ping_ms int
	speed   f64
	error   string
}

// Fetch Ubuntu mirror list
fn fetch_mirrors() ![]string {
	cmd := 'curl -s https://launchpad.net/ubuntu/+archivemirrors | grep -oP \'http[s]?://[^"]+\' | sort -u'
	job := osal.exec(cmd: cmd)!
	if job.exit_code != 0 {
		return error('Failed to fetch mirror list: ${job.output}')
	}
	mut mirrors := texttools.remove_empty_lines(job.output).split_into_lines()
	mirrors = mirrors.filter(it.contains('answers.launchpad.net') == false) // remove launchpad answers
	return mirrors
}

// Test download speed (download a small file)
fn test_download_speed(mirror string) f64 {
	test_file := '${mirror}/dists/plucky/Release' // small file usually available +-258KB
	start := time.now()
	resp := http.get(test_file) or { return -1.0 }
	if resp.status_code != 200 {
		return -1.0
	}
	elapsed := time.since(start).milliseconds()
	if elapsed == 0 {
		return -1.0
	}
	size_kb := f64(resp.body.len) / 1024.0
	return size_kb / elapsed // KB/sec
}

// Ping test (rough ICMP substitute using TCP connect on port 80), returns in ms
fn test_ping(mirror string, mut wg sync.WaitGroup, ch chan PerfResult) ! {
	defer { wg.done() }
	u := urllib.parse(mirror) or {
		ch <- PerfResult{
			url:     mirror
			ping_ms: -1
			speed:   0.0
		}
		return
	}
	host := u.host
	mut error := ''
	result := osal.http_ping(address: host, port: 80, timeout: 5000) or {
		error = err.msg()
		0
	}
	if result > 0 {
		ch <- PerfResult{
			url:     mirror
			ping_ms: result
			speed:   0.0
		}
	} else {
		ch <- PerfResult{
			url:   mirror
			error: error
		}
	}
}

// pub fn fix_mirrors() ! {
// 	println('Fetching Ubuntu mirrors...')
// 	mirrors := fetch_mirrors() or {
// 		print_backtrace()
// 		eprintln(err)
// 		return
// 	}
// 	// mut results := []PerfResult{}

// 	// mut c := 0

// 	// for m in mirrors {
// 	// 	c++
// 	// 	ping := test_ping(m)
// 	// 	println('Ping: ${ping} ms - ${mirrors.len} - ${c} ${m}')
// 	// 	$dbg;
// 	// }

// 	// for m in mirrors {
// 	// 	println('Speed: ${test_download_speed(m)} KB/s - ${m}')
// 	// 	$dbg;
// 	// 	speed := test_download_speed(m)
// 	// 	if speed > 0 {
// 	// 		ping := 0
// 	// 		results << PerfResult{
// 	// 			url:     m
// 	// 			ping_ms: ping
// 	// 			speed:   speed
// 	// 		}
// 	// 		println('✅ ${m} | ping: ${ping} ms | speed: ${speed:.2f} KB/s')
// 	// 	} else {
// 	// 		println('❌ ${m} skipped (unreachable or slow)')
// 	// 	}
// 	// 	$dbg;
// 	// }

// 	// println('\n🏆 Best mirrors:')
// 	// results.sort_with_compare(fn (a &PerfResult, b &PerfResult) int {
// 	// 	// Rank primarily by speed, secondarily by ping
// 	// 	if a.speed > b.speed {
// 	// 		return -1
// 	// 	} else if a.speed < b.speed {
// 	// 		return 1
// 	// 	} else {
// 	// 		return a.ping_ms - b.ping_ms
// 	// 	}
// 	// })

// 	// for r in results[..results.len.min(10)] {
// 	// 	println('${r.url} | ${r.ping_ms} ms | ${r.speed:.2f} KB/s')
// 	// }

// 	// println(results)
// 	// $dbg;
// }

pub fn fix_mirrors() ! {
	// Create wait group for servers
	mut wg := sync.new_waitgroup()
	wg.add(500)

	ch := chan PerfResult{cap: 1000}

	mut mirrors := ['http://ftp.mirror.tw/pub/ubuntu/ubuntu/']

	// mirrors := fetch_mirrors() or {
	// 	print_backtrace()
	// 	eprintln(err)
	// 	return
	// }
	mut c := 0

	mut result := []PerfResult{}

	for m in mirrors {
		c++
		println('Start background ping - ${mirrors.len} - ${c} ${m} - Queue len: ${ch.len} / ${ch.cap}')

		l := ch.len // number of elements in queue
		for l > ch.cap - 2 { // if queue is full, wait
			println('Queue full, wait till some are done')
			time.sleep(1 * time.second)
		}
		spawn test_ping(m, mut wg, ch)
	}

	for {
		value := <-ch or { // receive/pop values from the channel
			println('Channel closed')
			break
		}
		println('Received: ${value}')
	}

	println('All pings done 1')

	wg.wait()

	println('All pings done')
}
