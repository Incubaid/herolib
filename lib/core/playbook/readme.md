# heroscript

Our heroscript is a simple way to execute commands in a playbook. It allows you to define a series of actions that can be executed in sequence, making it easy to automate tasks and workflows.

## execute a playbook

the following will load heroscript and execute

```v
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.core.playcmds

// path string
// text string
// git_url string
// git_pull bool
// git_branch string
// git_reset bool
// session  ?&base.Session      is optional
mut plbook := playbook.new(path: "....")!

//now we run all the commands as they are pre-defined in herolib (herolib)
playcmds.run(mut plbook)!


```
## execute a heroscript and make executable

```bash
#!/usr/bin/env hero

!!play.echo content:'this is just a test'

!!play.echo content:'this is just another test'
```

you can now just execute this script and hero will interprete the content



## filtersort

```v

import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.core.playcmds

mut plbook := playbook.new(path: "....") or { panic(err) }

// filter parser based on the criteria
//```
// string for filter is $actor:$action, ... name and globs are possible (*,?)
//
// struct FilterSortArgs
// 	 priorities  map[int]string //filter and give priority
//```
// the action_names or actor_names can be a glob in match_glob .
// see https://modules.vlang.io/index.html#string.match_glob .
// the highest priority will always be chosen . (it can be a match happens 2x)
// return  []Action
actions:=plbook.filtersort({
    5:"sshagent:*",
    10:"doctree:*",
    11:"mdbooks:*",
    12:"mdbook:*",
})!

//now process the actions if we want to do it ourselves
for a in actions{
    mut p := action.params
    mut repo := p.get_default('repo', '')!
    if p.exists('coderoot') {
        coderoot = p.get_path_create('coderoot')!
    }
}

```

