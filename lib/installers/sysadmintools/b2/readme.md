# b2



To get started

```v


import freeflowuniverse.herolib.installers.something.b2 as b2_installer

heroscript:="
!!b2.configure name:'test'
    password: '1234'
    port: 7701

!!b2.start name:'test' reset:1 
"

b2_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= b2_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!b2.configure
    homedir: '/home/user/b2'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


