# PlayBook

## get & execute a playbook

HeroScript can be parsed into a `playbook.PlayBook` object, allowing structured access to actions and their parameters.

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

//now we run all the commands as they are pre-defined in herolib, this will execute the playbook and do all actions.
playcmds.run(mut plbook)!

```


