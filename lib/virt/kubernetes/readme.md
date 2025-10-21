# kubernetes



To get started

```v


import incubaid.herolib.installers.something.kubernetes as kubernetes_installer

heroscript:="
!!kubernetes.configure name:'test'
 password: '1234'
 port: 7701

!!kubernetes.start name:'test' reset:1 
"

kubernetes_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= kubernetes_installer.get()!
//installer.start(reset:true)!




```

## example heroscript


```hero
!!kubernetes.configure
    homedir: '/home/user/kubernetes'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```

