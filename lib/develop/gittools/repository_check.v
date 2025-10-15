module gittools

pub fn (mut repo GitRepo) check() ! {
	repo.init()!
	// if repo.lfs()! {
	// 	repo.lfs_check()!
	// }
}
