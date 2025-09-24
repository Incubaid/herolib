# wireguard



To get started

```v


import freeflowuniverse.herolib.installers.something.wireguard as wireguard_installer

heroscript:="
!!wireguard.configure name:'test'
    password: '1234'
    port: 7701

!!wireguard.start name:'test' reset:1 
"

wireguard_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= wireguard_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!wireguard.configure
    homedir: '/home/user/wireguard'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


