# how to use the playcmds

## simplified

```v
import incubaid.herolib.core.playcmds

playcmds.run(
 heroscript:''
 heroscript_path:''
    reset: false
 //plbook          ?PlayBook
)!

```

## with more control 

```v
#!/usr/bin/env -S v -n -w -gc none  -cg -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.develop.gittools
import incubaid.herolib.web.site
import incubaid.herolib.core.playcmds

url := "https://git.ourworld.tf/tfgrid/docs_tfgrid4/src/branch/main/ebooks/tech"

mysitepath := gittools.path(
   // git_pull: true
	// git_reset: true
    git_url: url
	git_root: '/tmp/code'
)!

playcmds.run(heroscript_path:mysitepath.path)!

mut mysite:=site.get(name:"tfgrid_tech")!
println(mysite)


```