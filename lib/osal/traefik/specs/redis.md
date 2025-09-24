# Traefik + Redis (KV provider): how to use it, where keys go, and how to notify Traefik

## 1) Enable the Redis provider (static config)

Add the Redis provider to Traefik’s **install/static** configuration (YAML example):

```yaml
providers:
  redis:
    endpoints:          # one or more Redis endpoints
      - "127.0.0.1:6379"
    rootKey: "traefik"  # KV root/prefix (default: traefik)
    db: 0               # optional
    username: ""        # optional
    password: ""        # optional
    tls:                # optional (use if Redis is TLS-enabled)
      ca: /path/to/ca.crt
      cert: /path/to/client.crt
      key: /path/to/client.key
      insecureSkipVerify: false
    sentinel:           # optional (if using Redis Sentinel)
      masterName: my-master
      # username/password/latencyStrategy/randomStrategy/replicaStrategy/useDisconnectedReplicas available
```

CLI equivalents (examples):
`--providers.redis.endpoints=127.0.0.1:6379 --providers.redis.rootkey=traefik --providers.redis.db=0` (see docs for all flags). ([Traefik Docs][1])

> **Important:** Traefik only *reads/watches* dynamic (routing) configuration from Redis. It doesn’t store anything there automatically. You populate keys yourself (see §3). ([Traefik Docs][1])

---

## 2) “Notifying” Traefik about changes (Redis keyspace notifications)

To have Traefik react to updates **without restart**, Redis must have **keyspace notifications** enabled. A safe, common setting is:

```bash
# temporary (runtime):
redis-cli CONFIG SET notify-keyspace-events AKE
# verify:
redis-cli CONFIG GET notify-keyspace-events
```

Or set `notify-keyspace-events AKE` in `redis.conf`, or via your cloud provider’s parameter group (e.g., ElastiCache / Memorystore). ([Traefik Docs][1], [Redis][2], [Traefik Labs Community Forum][3])

> Notes
>
> * Managed Redis services often **disable** these notifications by default for performance reasons—enable them explicitly. ([Traefik Docs][1])
> * `AKE` means “all” (`A`) generic/string/list/set/zset/stream + keyspace (`K`) + keyevent (`E`) messages. ([TECHCOMMUNITY.MICROSOFT.COM][4])

---

## 3) Where values must live in Redis (key layout)

Traefik expects a **hierarchical path** under `rootKey` (default `traefik`). You set **one string value per path**. Examples below show minimal keys for an HTTP route + service.

### 3.1 Minimal HTTP router + service

```
traefik/http/routers/myrouter/rule                      = Host(`kv.example.com`)
traefik/http/routers/myrouter/entryPoints/0             = web
traefik/http/routers/myrouter/entryPoints/1             = websecure
traefik/http/routers/myrouter/service                   = myservice

traefik/http/services/myservice/loadBalancer/servers/0/url = http://10.0.10.5:8080
traefik/http/services/myservice/loadBalancer/servers/1/url = http://10.0.10.6:8080
```

(Write these with `redis-cli SET <key> "<value>"`.) ([Traefik Docs][5])

### 3.2 Add middlewares and TLS (optional)

```
traefik/http/routers/myrouter/middlewares/0             = auth
traefik/http/routers/myrouter/middlewares/1             = prefix
traefik/http/routers/myrouter/tls                       = true
traefik/http/routers/myrouter/tls/certResolver          = myresolver
traefik/http/routers/myrouter/tls/domains/0/main        = example.org
traefik/http/routers/myrouter/tls/domains/0/sans/0      = dev.example.org
```

([Traefik Docs][5])

### 3.3 TCP example (e.g., pass-through services)

```
traefik/tcp/routers/mytcprouter/rule                    = HostSNI(`*`)
traefik/tcp/routers/mytcprouter/entryPoints/0           = redis-tcp
traefik/tcp/routers/mytcprouter/service                 = mytcpservice
traefik/tcp/routers/mytcprouter/tls/passthrough         = true

traefik/tcp/services/mytcpservice/loadBalancer/servers/0/address = 10.0.10.7:6379
```

([Traefik Docs][6])

> The full KV reference (all keys for routers/services/middlewares/TLS/options/observability) is here and shows many more fields you can set. ([Traefik Docs][6])

---

## 4) End-to-end quickstart (commands you can paste)

```bash
# 1) Enable keyspace notifications (see §2)
redis-cli CONFIG SET notify-keyspace-events AKE

# 2) Create minimal HTTP route + service (see §3.1)
redis-cli SET traefik/http/routers/myrouter/rule "Host(`kv.example.com`)"
redis-cli SET traefik/http/routers/myrouter/entryPoints/0 "web"
redis-cli SET traefik/http/routers/myrouter/entryPoints/1 "websecure"
redis-cli SET traefik/http/routers/myrouter/service "myservice"

redis-cli SET traefik/http/services/myservice/loadBalancer/servers/0/url "http://10.0.10.5:8080"
redis-cli SET traefik/http/services/myservice/loadBalancer/servers/1/url "http://10.0.10.6:8080"
```

Traefik will pick these up automatically (no restart) once keyspace notifications are on. ([Traefik Docs][1])

---

## 5) Operational tips / gotchas

* **Managed Redis**: enable `notify-keyspace-events` (e.g., ElastiCache parameter group; Memorystore config). Without it, Traefik won’t react to updates. ([Traefik Docs][1], [Traefik Labs Community Forum][3])
* **Persistence**: if you want the config to survive Redis restarts, enable AOF or snapshots per your ops policy. (General Redis ops guidance.) ([JupyterHub Traefik Proxy][7])
* **Sentinel / TLS**: configure the provider fields accordingly (see §1). ([Traefik Docs][1])
* **Deletions**: some users reported recent Traefik versions not always propagating *deletions* from Redis the same way as updates—test your workflow; if needed, set empty values or overwrite keys. Track open issues. ([GitHub][8], [Traefik Labs Community Forum][9])

---

## 6) Checklist

1. Traefik started with `providers.redis` pointing at your Redis. ([Traefik Docs][1])
2. `notify-keyspace-events` enabled (e.g., `AKE`). ([Traefik Docs][1], [Redis][2])
3. Keys created under `rootKey` (default `traefik`) following the **KV path schema** shown above. ([Traefik Docs][5])
4. Verify in Traefik dashboard/API that routers/services appear. (General provider behavior.) ([Traefik Docs][10])

---

### Sources

* Traefik Redis provider docs (static options & keyspace note). ([Traefik Docs][1])
* KV dynamic configuration reference (full key paths). ([Traefik Docs][6])
* KV provider routing examples (HTTP services/routers). ([Traefik Docs][5])
* Example KV layout (Hub ref, same model). ([Traefik Docs][11])
* Redis keyspace notifications (what `AKE` means). ([Redis][2], [TECHCOMMUNITY.MICROSOFT.COM][4])

If you want, I can output the exact `redis-cli` commands for any specific route/service you plan to add.

[1]: https://doc.traefik.io/traefik/providers/redis/ "Traefik Redis Documentation - Traefik"
[2]: https://redis.io/docs/latest/develop/pubsub/keyspace-notifications/?utm_source=chatgpt.com "Redis keyspace notifications | Docs"
[3]: https://community.traefik.io/t/traefik-not-re-configuring-using-aws-elasticicache-redis-on-change/5227?utm_source=chatgpt.com "Traefik not re-configuring using AWS Elasticicache Redis ..."
[4]: https://techcommunity.microsoft.com/blog/azurepaasblog/redis-keyspace-events-notifications/1551134?utm_source=chatgpt.com "Redis Keyspace Events Notifications"
[5]: https://doc.traefik.io/traefik/routing/providers/kv/ "Traefik Routing Configuration with KV stores - Traefik"
[6]: https://doc.traefik.io/traefik/reference/dynamic-configuration/kv/ "Traefik Dynamic Configuration with KV stores - Traefik"
[7]: https://jupyterhub-traefik-proxy.readthedocs.io/en/stable/redis.html?utm_source=chatgpt.com "Using TraefikRedisProxy - JupyterHub Traefik Proxy"
[8]: https://github.com/traefik/traefik/issues/11864?utm_source=chatgpt.com "Traefik does not handle rules deletion from redis kv #11864"
[9]: https://community.traefik.io/t/traefik-does-not-prune-deleted-rules-from-redis-kv/27789?utm_source=chatgpt.com "Traefik does not prune deleted rules from redis KV"
[10]: https://doc.traefik.io/traefik/providers/overview/?utm_source=chatgpt.com "Traefik Configuration Discovery Overview"
[11]: https://doc.traefik.io/traefik-hub/api-gateway/reference/ref-overview?utm_source=chatgpt.com "Install vs Routing Configuration | Traefik Hub Documentation"
