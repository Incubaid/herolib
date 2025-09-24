# yggdrasil



To get started

```v


import freeflowuniverse.herolib.installers.something.yggdrasil as yggdrasil_installer

heroscript:="
!!yggdrasil.configure name:'test'
    password: '1234'
    port: 7701

!!yggdrasil.start name:'test' reset:1 
"

yggdrasil_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= yggdrasil_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!yggdrasil.configure
    homedir: '/home/user/yggdrasil'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


