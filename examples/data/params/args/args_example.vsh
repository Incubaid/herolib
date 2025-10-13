#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.playbook
import incubaid.herolib.data.paramsparser
import os

const testpath = os.dir(@FILE) + '/data'

ap := playbook.new(path: testpath)!

mut test := map[string]string{}
test['root'] = 'YEH'
test['roott'] = 'YEH2'
for action in ap.actions {
	// action.params.replace(test)
	mut p := action.params
	p.replace(test)
	println(p)
}

txt := '

this is a text \${aVAR}

this is a text \${aVAR}

\${A}

'
// println(txt)
// println(params.regexfind(txt))
