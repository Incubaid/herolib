module ubuntu

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.texttools
import net.http
import os
import time
import net.urllib
import net

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
	println(size_kb)
	$dbg;
	return size_kb / elapsed // KB/sec
}

// Ping test (rough ICMP substitute using TCP connect on port 80), returns in ms
fn test_ping(mirror string) int {
	u := urllib.parse(mirror) or { return -1 }
	host := u.host
	start := time.now()
	mut c := net.dial_tcp('${host}:80') or { return -1 }
	c.close() or {}
	return int(time.since(start).milliseconds())
}

struct MirrorResult {
	url     string
	ping_ms int
	speed   f64
}

pub fn fix_mirrors() ! {
	println('Fetching Ubuntu mirrors...')
	mirrors := fetch_mirrors() or {
		print_backtrace()
		eprintln(err)
		return
	}
	mut results := []MirrorResult{}

	mut c := 0

	for m in mirrors {
		c++
		ping := test_ping(m)
		println('Ping: ${ping} ms - ${mirrors.len} - ${c} ${m}')
		$dbg;
	}

	for m in mirrors {
		println('Speed: ${test_download_speed(m)} KB/s - ${m}')
		$dbg;
		speed := test_download_speed(m)
		if speed > 0 {
			ping := 0
			results << MirrorResult{
				url:     m
				ping_ms: ping
				speed:   speed
			}
			println('✅ ${m} | ping: ${ping} ms | speed: ${speed:.2f} KB/s')
		} else {
			println('❌ ${m} skipped (unreachable or slow)')
		}
		$dbg;
	}

	println('\n🏆 Best mirrors:')
	results.sort_with_compare(fn (a &MirrorResult, b &MirrorResult) int {
		// Rank primarily by speed, secondarily by ping
		if a.speed > b.speed {
			return -1
		} else if a.speed < b.speed {
			return 1
		} else {
			return a.ping_ms - b.ping_ms
		}
	})

	// for r in results[..results.len.min(10)] {
	// 	println('${r.url} | ${r.ping_ms} ms | ${r.speed:.2f} KB/s')
	// }

	println(results)
	$dbg;
}
