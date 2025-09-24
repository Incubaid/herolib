module codewalker

@[params]
pub struct CodeWalkerArgs {
	// No fields required for now; kept for API stability
}

pub fn new(args CodeWalkerArgs) !CodeWalker {
	mut cw := CodeWalker{}
	cw.ignorematcher = gitignore_matcher_new()
	return cw
}
