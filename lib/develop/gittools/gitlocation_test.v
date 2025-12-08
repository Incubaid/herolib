module gittools

fn test_normalize_url() {
	// Test SSH URL with ssh:// prefix and git@ user
	assert normalize_url('ssh://git@forge.ourworld.tf/lhumina_code/docusaurus_template.git') == 'forge.ourworld.tf/lhumina_code/docusaurus_template.git'

	// Test SSH URL with just git@ prefix (no ssh://)
	assert normalize_url('git@github.com:vlang/v.git') == 'github.com/vlang/v.git'

	// Test HTTPS URL
	assert normalize_url('https://github.com/vlang/v.git') == 'github.com/vlang/v.git'

	// Test HTTP URL
	assert normalize_url('http://github.com/vlang/v.git') == 'github.com/vlang/v.git'

	// Test URL without any prefix (just domain)
	assert normalize_url('github.com/vlang/v') == 'github.com/vlang/v'

	// Test URL with trailing slash
	assert normalize_url('https://github.com/vlang/v/') == 'github.com/vlang/v'

	// Test SSH URL with port-style colon (git@host:path format)
	assert normalize_url('git@git.threefold.info:tfgrid/docs.git') == 'git.threefold.info/tfgrid/docs.git'

	// Test SSH URL with ssh:// and standard path (no colon after host)
	assert normalize_url('ssh://git@git.ourworld.tf/herocode/home.git') == 'git.ourworld.tf/herocode/home.git'

	// Test double slashes are normalized to single slash
	assert normalize_url('https://github.com//vlang//v') == 'github.com/vlang/v'
}

fn test_gitlocation_from_url() {
	mut gs := GitStructure{}

	// Test case 1: URL with src/branch/main
	url1 := 'https://git.threefold.info/tfgrid/docs_tfgrid4/src/branch/main/ebooks/tech'
	loc1 := gs.gitlocation_from_url(url1)!
	assert loc1.provider == 'git.threefold.info'
	assert loc1.account == 'tfgrid'
	assert loc1.name == 'docs_tfgrid4'
	assert loc1.branch_or_tag == 'main'
	assert loc1.path == 'ebooks/tech'
	assert loc1.anker == ''

	// Test case 2: URL with tree for branch
	url2 := 'https://github.com/vlang/v/tree/master/vlib'
	loc2 := gs.gitlocation_from_url(url2)!
	assert loc2.provider == 'github'
	assert loc2.account == 'vlang'
	assert loc2.name == 'v'
	assert loc2.branch_or_tag == 'master'
	assert loc2.path == 'vlib'
	assert loc2.anker == ''

	// Test case 3: URL with refs for branch
	url3 := 'https://github.com/vlang/v/refs/heads/master/vlib'
	loc3 := gs.gitlocation_from_url(url3)!
	assert loc3.provider == 'github'
	assert loc3.account == 'vlang'
	assert loc3.name == 'v'
	assert loc3.branch_or_tag == 'master'
	assert loc3.path == 'vlib'
	assert loc3.anker == ''

	// Test case 4: Simple URL without branch or path
	url4 := 'https://github.com/vlang/v'
	loc4 := gs.gitlocation_from_url(url4)!
	assert loc4.provider == 'github'
	assert loc4.account == 'vlang'
	assert loc4.name == 'v'
	assert loc4.branch_or_tag == ''
	assert loc4.path == ''
	assert loc4.anker == ''

	// Test case 5: URL with an anchor
	url5 := 'https://github.com/vlang/v/tree/master/vlib#L10'
	loc5 := gs.gitlocation_from_url(url5)!
	assert loc5.provider == 'github'
	assert loc5.account == 'vlang'
	assert loc5.name == 'v'
	assert loc5.branch_or_tag == 'master'
	assert loc5.path == 'vlib'
	assert loc5.anker == 'L10'
}
