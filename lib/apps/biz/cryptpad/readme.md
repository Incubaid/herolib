# cryptpad



To get started

```v


import incubaid.herolib.installers.something.cryptpad as cryptpad_installer

heroscript:="
!!cryptpad.configure name:'test'
 password: '1234'
 port: 7701

!!cryptpad.start name:'test' reset:1 
"

cryptpad_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= cryptpad_installer.get()!
//installer.start(reset:true)!




```

## example heroscript


```hero
!!cryptpad.configure
    homedir: '/home/user/cryptpad'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```

