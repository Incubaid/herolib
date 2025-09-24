
# Traefik Routers — Practical Guide

A **router** connects incoming traffic to a target **service**. It matches requests (or connections), optionally runs **middlewares**, and forwards to the chosen **service**. ([Traefik Docs][1])

---

## Quick examples

```yaml
# Dynamic (file provider) — HTTP: /foo -> service-foo
http:
  routers:
    my-router:
      rule: Path(`/foo`)
      service: service-foo
```

```toml
# Dynamic (file provider) — HTTP: /foo -> service-foo
[http.routers.my-router]
rule = "Path(`/foo`)"
service = "service-foo"
```

```yaml
# Dynamic — TCP: all non-TLS on :3306 -> database
tcp:
  routers:
    to-database:
      entryPoints: ["mysql"]
      rule: HostSNI(`*`)
      service: database
```

```yaml
# Static — define entrypoints
entryPoints:
  web:    { address: ":80" }
  mysql:  { address: ":3306" }
```

([Traefik Docs][1])

---

## HTTP Routers

### EntryPoints

* If omitted, an HTTP router listens on all default entry points; set `entryPoints` to scope it. ([Traefik Docs][1])

```yaml
http:
  routers:
    r1:
      rule: Host(`example.com`)
      service: s1
      entryPoints: ["web","websecure"]
```

### Rule (matchers)

A **rule** activates the router when it matches; then middlewares run, then the request is sent to the service. Common matchers (v3 syntax):

* `Host(...)`, `HostRegexp(...)`
* `Path(...)`, `PathPrefix(...)`, `PathRegexp(...)`
* `Header(...)`, `HeaderRegexp(...)`
* `Method(...)`
* `Query(...)`, `QueryRegexp(...)`
* `ClientIP(...)`
  See the full table in the official page. ([Traefik Docs][1])

### Priority

Routers sort by **rule length** (desc) when `priority` is unset. Set `priority` to override (Max: `MaxInt32-1000` on 32-bit, `MaxInt64-1000` on 64-bit). ([Traefik Docs][1])

### Rule Syntax (`ruleSyntax`)

* Traefik v3 introduces a new rule syntax; you can set per-router `ruleSyntax: v2|v3`.
* Default inherits from static `defaultRuleSyntax` (defaults to `v3`). ([Traefik Docs][1])

### Middlewares

Attach a **list** in order; names cannot contain `@`. Applied only if the rule matches. ([Traefik Docs][1])

```yaml
http:
  routers:
    r-auth:
      rule: Path(`/foo`)
      middlewares: [authentication]
      service: service-foo
```

### Service

Every HTTP router must target an **HTTP service** (not TCP). Some label-based providers auto-create defaults. ([Traefik Docs][1])

### TLS (HTTPS termination)

* Adding a `tls` section makes the router **HTTPS-only** and **terminates TLS** by default.
* To serve **both HTTP and HTTPS**, define **two routers**: one with `tls: {}` and one without.
* `tls.options`, `tls.certResolver`, and `tls.domains` follow the HTTP TLS reference. ([Traefik Docs][1])

### Observability (per-router)

Per-router toggles for `accessLogs`, `metrics`, `tracing`. Router-level settings override entrypoint defaults, but require the global features enabled first. Internal resources obey `AddInternals` guards. ([Traefik Docs][1])

```yaml
http:
  routers:
    r:
      rule: Path(`/foo`)
      service: s
      observability:
        accessLogs: false
        metrics: false
        tracing: false
```

---

## TCP Routers

### General

* If HTTP and TCP routers listen on the **same entry point**, **TCP routers apply first**; if none matches, HTTP routers take over.
* Names cannot contain `@`. ([Traefik Docs][1])

### EntryPoints & “server-first” protocols

* Omit `entryPoints` → listens on all default.
* For **server-first** protocols (e.g., SMTP), ensure **no TLS routers** exist on that entry point and have **at least one non-TLS TCP router** to avoid deadlocks (both sides waiting). ([Traefik Docs][1])

### Rule (matchers)

* `HostSNI(...)`, `HostSNIRegexp(...)` (for TLS SNI)
* `ClientIP(...)`
* `ALPN(...)`
  Same flow: match → middlewares → service. ([Traefik Docs][1])

### Priority & Rule Syntax

* Same priority model as HTTP; set `priority` to override.
* `ruleSyntax: v2|v3` supported per router (example below). ([Traefik Docs][1])

```yaml
tcp:
  routers:
    r-v3:
      rule: ClientIP(`192.168.0.11`) || ClientIP(`192.168.0.12`)
      ruleSyntax: v3
      service: s1
    r-v2:
      rule: ClientIP(`192.168.0.11`, `192.168.0.12`)
      ruleSyntax: v2
      service: s2
```

### Middlewares

Order matters; names cannot contain `@`. ([Traefik Docs][1])

### Services

TCP routers **must** target **TCP services** (not HTTP). ([Traefik Docs][1])

### TLS

* Adding `tls` makes the router **TLS-only**.
* Default is **TLS termination**; set `tls.passthrough: true` to forward encrypted bytes unchanged.
* `tls.options` (cipher suites, versions), `tls.certResolver`, `tls.domains` are supported when `HostSNI` is defined. ([Traefik Docs][1])

```yaml
tcp:
  routers:
    r-pass:
      rule: HostSNI(`db.example.com`)
      service: db
      tls:
        passthrough: true
```

**Postgres STARTTLS:** Traefik can detect Postgres’ STARTTLS negotiation and proceed with TLS routing; prefer client `sslmode=require`. Be careful with TLS passthrough and certain `sslmode` values. ([Traefik Docs][1])

---

## UDP Routers

### General

* UDP has no URL or SNI to match; UDP “routers” are effectively **load-balancers** with no rule criteria.
* Traefik maintains **sessions** (with a **timeout**) to map backend responses to clients. Configure timeout via `entryPoints.<name>.udp.timeout`. Names cannot contain `@`. ([Traefik Docs][1])

### EntryPoints

* Omit `entryPoints` → listens on all **UDP** entry points; specify to scope. ([Traefik Docs][1])

```yaml
udp:
  routers:
    r:
      entryPoints: ["streaming"]
      service: s1
```

### Services

UDP routers **must** target **UDP services** (not HTTP/TCP). ([Traefik Docs][1])

---

## Tips & gotchas

* `@` is **not allowed** in router, middleware, or service names. ([Traefik Docs][1])
* To serve the **same route on HTTP and HTTPS**, create **two routers** (with and without `tls`). ([Traefik Docs][1])
* Priority defaults to **rule length**; explicit `priority` wins and is often needed when a specific case should beat a broader matcher. ([Traefik Docs][1])
* **TCP vs HTTP precedence** on the same entry point: **TCP first**. ([Traefik Docs][1])

---

### Sources

Official Traefik docs — **Routers** (HTTP/TCP/UDP), examples, TLS, observability. ([Traefik Docs][1])

If you want this as a separate `.md` file in a specific structure (e.g., your repo), tell me the filename/path and I’ll format it accordingly.

[1]: https://doc.traefik.io/traefik/routing/routers/ "Traefik Routers Documentation - Traefik"
