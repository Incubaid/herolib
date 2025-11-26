
## to get started 

This script is run from your own computer or a VM on which you develop.

Make sure you have hero_secrets loaded

```bash
hero git pull  https://git.threefold.info/despiegk/hero_secrets
source ~/code/git.ourworld.tf/despiegk/hero_secrets/mysecrets.sh
```

## to e.g. install test1

```
~/code/github/incubaid/herolib/examples/virt/hetzner/hetzner_test1.vsh
```

keys available:

- hossnys (RSA 2048)
- Jan De Landtsheer (ED25519 256)
- mahmoud (ED25519 256)
- kristof (ED25519 256)
- maxime (ED25519 256)

you can select another key in the script

> still to do, support our example key which is installed using mysecrets.sh


## hetzner troubleshoot info

get the login passwd from: 

https://robot.hetzner.com/preferences/index

```bash
curl -u "#ws+JdQtGCdL:..." https://robot-ws.your-server.de/server
```
