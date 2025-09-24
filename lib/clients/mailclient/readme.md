# mailclient


To get started

```v

import freeflowuniverse.herolib.clients.mailclient


//remove the previous one, otherwise the env variables are not read
mailclient.config_delete(name:"test")!

// env variables which need to be set are:
// - MAIL_FROM=...
// - MAIL_PASSWORD=...
// - MAIL_PORT=465
// - MAIL_SERVER=...
// - MAIL_USERNAME=...


mut client:= mailclient.get(name:"test")!

println(client)

client.send(subject:'this is a test',to:'kristof@incubaid.com',body:'
    this is my email content
    ')!

```

## example heroscript

```hero
!!mailclient.configure
    secret: '...'
    host: 'localhost'
    port: 8888
```

## use of env variables

if you have a secrets file you could import as

```bash
//e.g.  source ~/code/git.threefold.info/despiegk/hero_secrets/mysecrets.sh
```

following env variables are supported

- MAIL_FROM=
- MAIL_PASSWORD=
- MAIL_PORT=465
- MAIL_SERVER=smtp-relay.brevo.com
- MAIL_USERNAME=kristof@incubaid.com

these variables will only be set at configure time


## brevo remark

- use ssl
- use port: 465