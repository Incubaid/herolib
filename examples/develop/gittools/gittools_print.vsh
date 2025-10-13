#!/usr/bin/env -S v -n -w -gc none -cg  -cc tcc -d use_openssl -enable-globals run

// #!/usr/bin/env -S v -n -w -cg  -d use_openssl -enable-globals run
//-parallel-cc
import os
import incubaid.herolib.develop.gittools

mut gs := gittools.get(reload: true)!

gs.repos_print()!
