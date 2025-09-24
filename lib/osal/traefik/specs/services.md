

# Traefik Services (HTTP/TCP/UDP)

Services define **how Traefik reaches your backends** and how requests are **load-balanced** across them. Every service has a load balancer—even with a single server. ([Traefik Docs][1])

---

## Quick examples

```yaml
# Dynamic config (file provider)
http:
  services:
    web:
      loadBalancer:
        servers:
          - url: "http://10.0.0.11:8080/"
          - url: "http://10.0.0.12:8080/"

tcp:
  services:
    db:
      loadBalancer:
        servers:
          - address: "10.0.0.21:5432"
          - address: "10.0.0.22:5432"

udp:
  services:
    dns:
      loadBalancer:
        servers:
          - address: "10.0.0.31:53"
          - address: "10.0.0.32:53"
```

([Traefik Docs][1])

---

## HTTP services

### Servers Load Balancer

* **servers\[].url** – each backend instance.
* **preservePath** – keep the path segment of the URL when forwarding (note: not preserved for health-check requests). ([Traefik Docs][1])

```yaml
http:
  services:
    api:
      loadBalancer:
        servers:
          - url: "http://10.0.0.10/base"
            preservePath: true
```

#### Load-balancing strategy

* **WRR (default)** – optional **weight** per server.
* **P2C** – “power of two choices”; picks two random servers, chooses the one with fewer active requests. ([Traefik Docs][1])

```yaml
# WRR with weights
http:
  services:
    api:
      loadBalancer:
        servers:
          - url: "http://10.0.0.10/"; weight: 2
          - url: "http://10.0.0.11/"; weight: 1

# P2C
http:
  services:
    api:
      loadBalancer:
        strategy: p2c
        servers:
          - url: "http://10.0.0.10/"
          - url: "http://10.0.0.11/"
          - url: "http://10.0.0.12/"
```

([Traefik Docs][1])

#### Sticky sessions

Adds an affinity cookie so subsequent requests hit the same server.

* Works across nested LBs if stickiness is enabled at **each** level.
* If the chosen server becomes unhealthy, Traefik selects a new one and updates the cookie.
* Cookie options: `name`, `secure`, `httpOnly`, `sameSite`, `domain`, `maxAge`. ([Traefik Docs][1])

```yaml
http:
  services:
    web:
      loadBalancer:
        sticky:
          cookie:
            name: app_affinity
            secure: true
            httpOnly: true
            sameSite: lax
            domain: example.com
```

#### Health check

Periodically probes backends and **removes unhealthy servers** from rotation.

* HTTP(S): healthy if status is 2xx/3xx (or a configured status).
* gRPC: healthy if it returns `SERVING` (gRPC health v1).
* Options include `path`, `interval`, `timeout`, `scheme`, `hostname`, `port`. ([Traefik Docs][1])

```yaml
http:
  services:
    web:
      loadBalancer:
        healthCheck:
          path: /health
          interval: 10s
          timeout: 3s
```

#### Pass Host Header

Controls forwarding of the original `Host` header. **Default: true**. ([Traefik Docs][1])

```yaml
http:
  services:
    web:
      loadBalancer:
        passHostHeader: false
```

#### ServersTransport (HTTP)

Fine-tunes the connection from Traefik to your upstreams.

* TLS: `serverName`, `certificates`, `insecureSkipVerify`, `rootCAs`, `peerCertURI`, SPIFFE (`spiffe.ids`, `spiffe.trustDomain`)
* HTTP/2 toggle: `disableHTTP2`
* Pooling: `maxIdleConnsPerHost`
* Timeouts (`forwardingTimeouts`): `dialTimeout`, `responseHeaderTimeout`, `idleConnTimeout`, `readIdleTimeout`, `pingTimeout`
  Attach by name via `loadBalancer.serversTransport`. ([Traefik Docs][1])

```yaml
http:
  serversTransports:
    mtls:
      rootCAs:
        - /etc/ssl/my-ca.pem
      serverName: backend.internal
      insecureSkipVerify: false
      forwardingTimeouts:
        responseHeaderTimeout: "1s"

http:
  services:
    web:
      loadBalancer:
        serversTransport: mtls
        servers:
          - url: "https://10.0.0.10:8443/"
```

#### Response forwarding

Control how Traefik flushes response bytes to clients.

* `flushInterval` (ms): default **100**; negative = flush after each write; streaming responses are auto-flushed. ([Traefik Docs][1])

```yaml
http:
  services:
    streamy:
      loadBalancer:
        responseForwarding:
          flushInterval: 50
```

---

## Composite HTTP services

### Weighted Round Robin (service)

Combine **services** (not just servers) with weights; health status propagates upward if enabled. ([Traefik Docs][1])

### Mirroring (service)

Send requests to a **main service** and mirror a percentage to others.

* Defaults: `percent` = 0 (no traffic), `mirrorBody` = true, `maxBodySize` = -1 (unlimited).
* Providers: File, CRD IngressRoute.
* Health status can propagate upward (File provider). ([Traefik Docs][1])

```yaml
http:
  services:
    mirrored-api:
      mirroring:
        service: appv1
        mirrorBody: false
        maxBodySize: 1024
        mirrors:
          - name: appv2
            percent: 10
```

### Failover (service)

Route to **fallback** only when **main** is unreachable (relies on HealthCheck).

* Currently available with the **File** provider.
* HealthCheck on a Failover service requires all descendants to also enable it. ([Traefik Docs][1])

```yaml
http:
  services:
    app:
      failover:
        service: main
        fallback: backup

    main:
      loadBalancer:
        healthCheck: { path: /status, interval: 10s, timeout: 3s }
        servers: [{ url: "http://10.0.0.50/" }]

    backup:
      loadBalancer:
        servers: [{ url: "http://10.0.0.60/" }]
```

---

## TCP services (summary)

* **servers\[].address** (`host:port`), optional **tls** to upstream, attach a **ServersTransport** (TCP) with `dialTimeout`, `dialKeepAlive`, `terminationDelay`, TLS/SPIFEE options, and optional **PROXY Protocol** send. ([Traefik Docs][1])

---

## UDP services (summary)

* **servers\[].address** (`host:port`). Weighted round robin supported. ([Traefik Docs][1])

---

## Notes & gotchas

* Stickiness across nested load balancers requires enabling sticky at **each** level, and clients will carry **multiple key/value pairs** in the cookie. ([Traefik Docs][1])
* Health checks: enabling at a parent requires **all descendants** to support/enable it; otherwise service creation fails (applies to Mirroring/Failover health-check sections). ([Traefik Docs][1])

---

**Source:** Traefik “Routing & Load Balancing → Services” (current docs). ([Traefik Docs][1])

[1]: https://doc.traefik.io/traefik/routing/services/ "Traefik Services Documentation - Traefik"
