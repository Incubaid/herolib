module herofs



//copy data from filesystem into the VFS
fn (mut self Fs) import(src string, dest string)!{
	panic("implement")
}

//copy dataa from VFS fo FS
fn (mut self Fs) export(src string, dest string)!{
	panic("implement")
}