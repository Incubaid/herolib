module redisclient

@[params]
pub struct RedisURL {
	address string = '127.0.0.1'
	port    int    = 6379
	db      int
}

pub fn get_redis_url(url string) !RedisURL {
	if !url.contains(':') {
		return error('url doesnt contain port')
	} else {
		return RedisURL{
			address: url.all_before_last(':')
			port:    url.all_after_last(':').u16()
		}
	}
}

pub fn core_get(url RedisURL) !&Redis {
	mut r := new('${url.address}:${url.port}')!
	if url.db>0{
		r.selectdb(url.db)!
	}
	return r
}


//give a test db, if db is 0, we will set it on 31
pub fn test_get(url_ RedisURL) !&Redis {
	mut url:=url_
	if url.db==0{
		url.db=31
	}
	return core_get(url)!
}

//delete the test db
pub fn test_delete(url_ RedisURL) !&Redis {
	mut r:= test_get(url)!
	r.flush()!
}