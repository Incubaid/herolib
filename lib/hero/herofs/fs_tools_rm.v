module herofs



fn (mut self Fs) rm(args FindOptions)!{
	for item in self.find(args)!{
		panic("implement")
	}	
}