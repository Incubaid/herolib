# bun



To get started

```v


import freeflowuniverse.herolib.installers.something.bun as bun_installer

heroscript:="
!!bun.configure name:'test'
    password: '1234'
    port: 7701

!!bun.start name:'test' reset:1 
"

bun_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= bun_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!bun.configure
    homedir: '/home/user/bun'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


