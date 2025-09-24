# restic



To get started

```v


import freeflowuniverse.herolib.installers.something.restic as restic_installer

heroscript:="
!!restic.configure name:'test'
    password: '1234'
    port: 7701

!!restic.start name:'test' reset:1 
"

restic_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= restic_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!restic.configure
    homedir: '/home/user/restic'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


