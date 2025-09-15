module herofs



fn (mut self Fs) cp(dest string,args FindOptions)!{
	for item in self.find(args)!{
		panic("implement")
	}	
}