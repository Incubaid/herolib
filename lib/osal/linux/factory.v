module linux

@[heap]
pub struct LinuxFactory {
pub mut:
	username string
}

@[params]
pub struct LinuxNewArgs {
pub:
	username string
}

// return screen instance
pub fn new(args LinuxNewArgs) !LinuxFactory {
	mut t := LinuxFactory{
		username: args.username
	}
	return t
}
