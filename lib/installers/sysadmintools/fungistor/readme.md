# fungistor



To get started

```v


import freeflowuniverse.herolib.installers.something.fungistor as fungistor_installer

heroscript:="
!!fungistor.configure name:'test'
    password: '1234'
    port: 7701

!!fungistor.start name:'test' reset:1 
"

fungistor_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= fungistor_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!fungistor.configure
    homedir: '/home/user/fungistor'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


