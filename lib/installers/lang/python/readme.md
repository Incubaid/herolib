# python



To get started

```v


import freeflowuniverse.herolib.installers.something.python as python_installer

heroscript:="
!!python.configure name:'test'
    password: '1234'
    port: 7701

!!python.start name:'test' reset:1 
"

python_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= python_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!python.configure
    homedir: '/home/user/python'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


