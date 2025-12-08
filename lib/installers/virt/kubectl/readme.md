# kubectl



To get started

```v


import incubaid.herolib.installers.something.kubectl as kubectl_installer

heroscript:="
!!kubectl.configure name:'test'
 password: '1234'
 port: 7701

!!kubectl.start name:'test' reset:1 
"

kubectl_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= kubectl_installer.get()!
//installer.start(reset:true)!




```

## example heroscript


```hero
!!kubectl.configure
    homedir: '/home/user/kubectl'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```

