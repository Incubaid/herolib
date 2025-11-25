# kubernetes_installer



To get started

```v


import incubaid.herolib.installers.something.kubernetes_installer as kubernetes_installer_installer

heroscript:="
!!kubernetes_installer.configure name:'test'
 password: '1234'
 port: 7701

!!kubernetes_installer.start name:'test' reset:1 
"

kubernetes_installer_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= kubernetes_installer_installer.get()!
//installer.start(reset:true)!




```

## example heroscript


```hero
!!kubernetes_installer.configure
    homedir: '/home/user/kubernetes_installer'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```

