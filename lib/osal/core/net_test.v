module core

fn test_ipaddr_pub_get() {
	ipaddr := ipaddr_pub_get()!
	assert ipaddr != ''
}

fn test_ping() {
	x := ping(address: '127.0.0.1', retry: 1)!
	assert x == true
}

fn test_ping_timeout() ! {
	x := ping(address: '192.168.145.154', retry: 5, nr_ok: 1)!
	assert x == false
}

fn test_ping_unknownhost() ! {
	x := ping(address: '12.902.219.1', retry: 1, nr_ok: 1)!
	assert x == false
}
