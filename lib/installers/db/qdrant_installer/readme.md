# qdrant

Is a powerfull db for embedding for AI Agents.

To get started

```v

import freeflowuniverse.herolib.installers.db.qdrant_installer

heroscript:="
!!qdrant.configure name:'test'
    password: '1234'
    port: 7701

!!qdrant.start name:'test' reset:1 
"

qdrant_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= qdrant_installer.get()!
//installer.start(reset:true)!




```
