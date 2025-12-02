# erpnext



To get started

```v


import incubaid.herolib.installers.something.erpnext as erpnext_installer

heroscript:="
!!erpnext.configure name:'test'
 password: '1234'
 port: 7701

!!erpnext.start name:'test' reset:1 
"

erpnext_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= erpnext_installer.get()!
//installer.start(reset:true)!




```

## example heroscript


```hero
!!erpnext.configure
    homedir: '/home/user/erpnext'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```

