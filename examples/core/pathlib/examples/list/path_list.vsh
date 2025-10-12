#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.pathlib
import os

const testpath3 = os.dir(@FILE) + '/../../..'

mut p := pathlib.get_dir(path: testpath3)!
// IMPORTANT TO HAVE r'...   the r in front
pl := p.list(regex: [r'.*\.v$'])!
println(pl)
