module herofs

// MoveOptions provides options for move operations
@[params]
pub struct FSMoveArgs {
pub mut:
	overwrite       bool // Overwrite existing files at destination
	src string
	dest string
}

//if overwrite is false and exist then give error
//works for file and link and dir
//there is no physical move, its just changing the child in the dir we move too
fn (mut self Fs) move(args FSMoveArgs)!{
	panic("implement")
}