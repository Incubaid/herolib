# lima

To get started

```v


import incubaid.herolib.installers.virt.lima as lima_installer

heroscript:="
!!lima.install
"

lima_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
mut installer:= lima_installer.get()!
installer.start(reset:true)!




```
