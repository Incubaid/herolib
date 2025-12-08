# Installer Refactoring Status

Refactoring installers to use instance-based API pattern (methods on config structs instead of module-level functions).

## Completed ✅
- horus/coordinator
- horus/supervisor
- horus/herorunner
- horus/osirisrunner
- horus/salrunner
- base/redis
- infra/coredns

## In Progress 🔄

## Does Not Compile ❌
- db/cometbft (missing core import, model has undefined fields password/secret)
- db/postgresql (missing zinit import)
- db/qdrant_installer (osal.cputype() doesn't exist)
- db/zerodb (missing zinit import, zerodb_client API changes)

## To Do 📋
- db/meilisearch_installer
- infra/gitea
- infra/livekit
- infra/zinit_installer
- k8s/cryptpad
- k8s/element_chat
- lang/golang
- lang/nodejs
- lang/python
- lang/rust
- net/mycelium_installer
- net/wireguard_installer
- sysadmintools/actrunner
- sysadmintools/b2
- sysadmintools/fungistor
- sysadmintools/garage_s3
- sysadmintools/grafana
- sysadmintools/prometheus
- sysadmintools/rclone
- sysadmintools/restic
- threefold/griddriver
- virt/cloudhypervisor
- virt/docker
- virt/herorunner
- virt/kubernetes_installer
- virt/lima
- virt/pacman
- virt/podman
- virt/youki
- web/bun
- web/lighttpd
- web/nginx
- web/traefik
