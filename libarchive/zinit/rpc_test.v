module zinit

import os
import time
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.osal.core as osal

fn test_zinit() {
	if !core.is_linux()! {
		// zinit is only supported on linux
		return
	}

	// TODO: use zinit installer to install zinit
	// this is a workaround since we can't import zinit installer due to circular dependency
	zinit_version := os.execute('zinit --version')
	if zinit_version.exit_code != 0 {
		release_url := 'https://github.com/threefoldtech/zinit/releases/download/v0.2.14/zinit'

		mut dest := osal.download(
			url:        release_url
			minsize_kb: 2000
			reset:      true
			dest:       '/tmp/zinit'
		)!

		chmod_cmd := os.execute('chmod +x /tmp/zinit')
		assert chmod_cmd.exit_code == 0, 'failed to chmod +x /tmp/zinit: ${chmod_cmd.output}'
	}

	this_dir := os.dir(@FILE)
	// you need to have zinit in your path to run this test
	spawn os.execute('/tmp/zinit -s ${this_dir}/zinit/zinit.sock init -c ${this_dir}/zinit')
	time.sleep(time.second)

	client := new_rpc_client(socket_path: '${this_dir}/zinit/zinit.sock')

	mut ls := client.list()!
	mut want_ls := {
		'service_1': 'Running'
		'service_2': 'Running'
	}
	assert ls == want_ls

	mut st := client.status('service_2')!
	assert st.after == {
		'service_1': 'Running'
	}
	assert st.name == 'service_2'
	assert st.state == 'Running'
	assert st.target == 'Up'

	client.stop('service_2')!
	st = client.status('service_2')!
	assert st.target == 'Down'

	time.sleep(time.millisecond * 10)
	client.forget('service_2')!
	ls = client.list()!
	want_ls = {
		'service_1': 'Running'
	}
	assert ls == want_ls

	client.monitor('service_2')!
	time.sleep(time.millisecond * 10)
	st = client.status('service_2')!
	assert st.after == {
		'service_1': 'Running'
	}
	assert st.name == 'service_2'
	assert st.state == 'Running'
	assert st.target == 'Up'

	client.stop('service_2')!
	time.sleep(time.millisecond * 10)
	client.start('service_2')!
	st = client.status('service_2')!
	assert st.target == 'Up'

	client.kill('service_1', 'sigterm')!
	time.sleep(time.millisecond * 10)
	st = client.status('service_1')!
	assert st.state.contains('SIGTERM')

	// Remove the socet file
	os.rm('${this_dir}/zinit/zinit.sock')!
}
