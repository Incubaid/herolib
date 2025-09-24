# dify

dify

To get started

```v


import freeflowuniverse.herolib.installers.something.dify as dify_installer

heroscript:="
!!dify.configure name:'test'
    password: '1234'
    port: 7701

!!dify.start name:'test' reset:1 
"

dify_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= dify_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!dify.configure
    homedir: '/home/user/dify'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


