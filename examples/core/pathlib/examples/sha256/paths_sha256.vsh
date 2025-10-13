#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.pathlib
import os

const testpath4 = os.dir(@FILE) + '/paths_sha256.vsh'

mut p := pathlib.get_file(path: testpath4)!
s := p.sha256()!
println(s)
