# Traefik EntryPoints — Concise Guide (v3)

> Source docs: Traefik “Routing & Load Balancing → EntryPoints” and “Reference → Install Configuration → EntryPoints” (links in chat).

## What are EntryPoints
EntryPoints are the network entry points into Traefik. They define **which port and protocol (TCP/UDP)** Traefik listens on for incoming traffic. An entryPoint can be referenced by routers (HTTP/TCP/UDP).

---

## Quick Configuration Examples

### Port 80 only
```yaml
# Static configuration
entryPoints:
  web:
    address: ":80"
```
```toml
[entryPoints]
  [entryPoints.web]
    address = ":80"
```
```bash
# CLI
--entryPoints.web.address=:80
```

### Ports 80 & 443
```yaml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
```
```toml
[entryPoints]
  [entryPoints.web]
    address = ":80"

  [entryPoints.websecure]
    address = ":443"
```
```bash
--entryPoints.web.address=:80
--entryPoints.websecure.address=:443
```

### UDP on port 1704
```yaml
entryPoints:
  streaming:
    address: ":1704/udp"
```
```toml
[entryPoints]
  [entryPoints.streaming]
    address = ":1704/udp"
```
```bash
--entryPoints.streaming.address=:1704/udp
```

### TCP **and** UDP on the same port (3179)
```yaml
entryPoints:
  tcpep:
    address: ":3179"      # TCP
  udpep:
    address: ":3179/udp"  # UDP
```
```toml
[entryPoints]
  [entryPoints.tcpep]
    address = ":3179"
  [entryPoints.udpep]
    address = ":3179/udp"
```
```bash
--entryPoints.tcpep.address=:3179
--entryPoints.udpep.address=:3179/udp
```

### Listen on specific IPs only
```yaml
entryPoints:
  specificIPv4:
    address: "192.168.2.7:8888"
  specificIPv6:
    address: "[2001:db8::1]:8888"
```
```toml
[entryPoints.specificIPv4]
  address = "192.168.2.7:8888"
[entryPoints.specificIPv6]
  address = "[2001:db8::1]:8888"
```
```bash
--entryPoints.specificIPv4.address=192.168.2.7:8888
--entryPoints.specificIPv6.address=[2001:db8::1]:8888
```

---

## General Structure (Static Configuration)

```yaml
entryPoints:
  <name>:
    address: ":8888"                 # or ":8888/tcp" or ":8888/udp"
    http2:
      maxConcurrentStreams: 250
    http3:
      advertisedPort: 443            # requires TLS; see notes
    transport:
      lifeCycle:
        requestAcceptGraceTimeout: 42s
        graceTimeOut: 42s
      respondingTimeouts:
        readTimeout: 60s
        writeTimeout: 0s
        idleTimeout: 180s
    proxyProtocol:
      insecure: true                 # trust all (testing only)
      trustedIPs:
        - "127.0.0.1"
        - "192.168.0.1"
    forwardedHeaders:
      insecure: true                 # trust all (testing only)
      trustedIPs:
        - "127.0.0.1/32"
        - "192.168.1.7"
      connection:
        - "foobar"
```
```toml
[entryPoints]
  [entryPoints.name]
    address = ":8888"
    [entryPoints.name.http2]
      maxConcurrentStreams = 250
    [entryPoints.name.http3]
      advertisedPort = 443
    [entryPoints.name.transport]
      [entryPoints.name.transport.lifeCycle]
        requestAcceptGraceTimeout = "42s"
        graceTimeOut = "42s"
      [entryPoints.name.transport.respondingTimeouts]
        readTimeout  = "60s"
        writeTimeout = "0s"
        idleTimeout  = "180s"
    [entryPoints.name.proxyProtocol]
      insecure   = true
      trustedIPs = ["127.0.0.1", "192.168.0.1"]
    [entryPoints.name.forwardedHeaders]
      insecure   = true
      trustedIPs = ["127.0.0.1/32", "192.168.1.7"]
      connection = ["foobar"]
```
```bash
--entryPoints.name.address=:8888
--entryPoints.name.http2.maxConcurrentStreams=250
--entryPoints.name.http3.advertisedport=443
--entryPoints.name.transport.lifeCycle.requestAcceptGraceTimeout=42s
--entryPoints.name.transport.lifeCycle.graceTimeOut=42s
--entryPoints.name.transport.respondingTimeouts.readTimeout=60s
--entryPoints.name.transport.respondingTimeouts.writeTimeout=0s
--entryPoints.name.transport.respondingTimeouts.idleTimeout=180s
--entryPoints.name.proxyProtocol.insecure=true
--entryPoints.name.proxyProtocol.trustedIPs=127.0.0.1,192.168.0.1
--entryPoints.name.forwardedHeaders.insecure=true
--entryPoints.name.forwardedHeaders.trustedIPs=127.0.0.1/32,192.168.1.7
--entryPoints.name.forwardedHeaders.connection=foobar
```

---

## Key Options (Explained)

### `address`
- Format: `[host]:port[/tcp|/udp]`. If protocol omitted ⇒ **TCP**.
- To use **both TCP & UDP** on the same port, define **two** entryPoints (one per protocol).

### `allowACMEByPass` (bool, default **false**)
- Allow user-defined routers to handle **ACME HTTP/TLS challenges** instead of Traefik’s built-in handlers (useful if services also run their own ACME).  
  ```yaml
  entryPoints:
    foo:
      allowACMEByPass: true
  ```

### `reusePort` (bool, default **false**)
- Enables the OS `SO_REUSEPORT` option: multiple Traefik processes (or entryPoints) can **listen on the same TCP/UDP port**; the kernel load-balances incoming connections.
- Supported on **Linux, FreeBSD, OpenBSD, Darwin**.
- Example (same port, different hosts/IPs):
  ```yaml
  entryPoints:
    web:
      address: ":80"
      reusePort: true
    privateWeb:
      address: "192.168.1.2:80"
      reusePort: true
  ```

### `asDefault` (bool, default **false**)
- Marks this entryPoint as **default** for HTTP/TCP routers **that don’t specify** `entryPoints`.  
  ```yaml
  entryPoints:
    web:
      address: ":80"
    websecure:
      address: ":443"
      asDefault: true
  ```
- UDP entryPoints are **never** part of the default list.
- Built-in `traefik` entryPoint is **always excluded**.

### HTTP/2
- `http2.maxConcurrentStreams` (default **250**): max concurrent streams per connection.

### HTTP/3
- Enable by adding `http3: {}` (on a **TCP** entryPoint with **TLS**).  
- When enabled on port **N**, Traefik also opens **UDP N** for HTTP/3.  
- `http3.advertisedPort`: override the UDP port advertised via `alt-svc` (useful behind a different public port).

### Forwarded Headers
- Trust `X-Forwarded-*` only from `forwardedHeaders.trustedIPs`, or set `forwardedHeaders.insecure: true` (testing only).
- `forwardedHeaders.connection`: headers listed here are allowed to pass through the middleware chain before Traefik drops `Connection`-listed headers per RFC 7230.

### Transport Timeouts
- `transport.respondingTimeouts.readTimeout` (default **60s**): max duration to read the entire request (incl. body).
- `transport.respondingTimeouts.writeTimeout` (default **0s**): max duration for writing the response (0 = disabled).
- `transport.respondingTimeouts.idleTimeout` (default **180s**): max keep-alive idle time.

### Transport LifeCycle (graceful shutdown)
- `transport.lifeCycle.requestAcceptGraceTimeout` (default **0s**): keep accepting requests **before** starting graceful termination.
- `transport.lifeCycle.graceTimeOut` (default **10s**): time to let in-flight requests finish **after** Traefik stops accepting new ones.

### ProxyProtocol
- Enable accepting the **HAProxy PROXY** header and/or trust only from specific IPs.
  ```yaml
  entryPoints:
    name:
      proxyProtocol:
        insecure: true         # trust all (testing only)
        trustedIPs:
          - "127.0.0.1"
          - "192.168.0.1"
  ```

---

## HTTP Options (per entryPoint)

### Redirection → `http.redirections.entryPoint`
Redirect everything on one entryPoint to another (often `web` → `websecure`), and optionally change scheme.
```yaml
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure        # or ":443"
          scheme: https        # default is https
          permanent: true      # 308/301
```
```toml
[entryPoints.web.http.redirections]
  entryPoint = "websecure"
  scheme     = "https"
  permanent  = true
```

- `http.redirections.entryPoint.priority`: default priority for routers bound to the entryPoint (default `2147483646`).

### Encode Query Semicolons → `http.encodeQuerySemicolons` (bool, default **false**)
- If `true`, non-encoded semicolons in the query string are **encoded** before forwarding (prevents interpreting `;` as query parameter separators).

### SanitizePath → `http.sanitizePath` (bool, default **false**)
- Enable request **path sanitization/normalization** before routing.

### Middlewares → `http.middlewares`
Apply middlewares by name (with provider suffix) **to all routers attached to this entryPoint**.
```yaml
entryPoints:
  websecure:
    address: ":443"
    tls: {}
    middlewares:
      - auth@kubernetescrd
      - strip@kubernetescrd
```

### TLS → `http.tls`
Attach TLS options/resolvers and SNI domains at the entryPoint level (common for `websecure`).
```yaml
# YAML
entryPoints:
  websecure:
    address: ":443"
    http:
      tls:
        options: foobar
        certResolver: leresolver
        domains:
          - main: example.com
            sans:
              - foo.example.com
              - bar.example.com
          - main: test.com
            sans:
              - foo.test.com
              - bar.test.com
```
```bash
--entryPoints.websecure.http.tls.options=foobar
--entryPoints.websecure.http.tls.certResolver=leresolver
--entryPoints.websecure.http.tls.domains[0].main=example.com
--entryPoints.websecure.http.tls.domains[0].sans=foo.example.com,bar.example.com
--entryPoints.websecure.http.tls.domains[1].main=test.com
--entryPoints.websecure.http.tls.domains[1].sans=foo.test.com,bar.test.com
```

---

## UDP Options

### `udp.timeout` (default **3s**)
Release idle UDP session resources after this duration.
```yaml
entryPoints:
  foo:
    address: ":8000/udp"
    udp:
      timeout: 10s
```
```toml
[entryPoints.foo]
  address = ":8000/udp"
  [entryPoints.foo.udp]
    timeout = "10s"
```
```bash
--entryPoints.foo.address=:8000/udp
--entryPoints.foo.udp.timeout=10s
```

---

## Systemd Socket Activation
- Traefik supports **systemd socket activation**. If an fd name matches an entryPoint name, Traefik uses that fd as the listener.
  ```bash
  systemd-socket-activate -l 80 -l 443 --fdname web:websecure ./traefik --entrypoints.web --entrypoints.websecure
  ```
- If using UDP with socket activation, the entryPoint address must include `/udp` (e.g., `--entrypoints.my-udp-entrypoint.address=/udp`).
- **Docker** does not support socket activation; **Podman** does.
- Each systemd socket file should define a **single** Listen directive, **except** for HTTP/3 which needs **both** `ListenStream` and `ListenDatagram` (same port). To run TCP **and** UDP on the same port, use **separate** socket files bound to different entryPoint names.

---

## Observability Options (per entryPoint)
> These control **defaults**; a router’s own observability config can opt out.

```yaml
entryPoints:
  foo:
    address: ":8000"
    observability:
      accessLogs: false  # default true
      metrics:    false  # default true
      tracing:    false  # default true
```
```toml
[entryPoints.foo]
  address = ":8000"
  [entryPoints.foo.observability]
    accessLogs = false
    metrics    = false
    tracing    = false
```
```bash
--entryPoints.foo.observability.accessLogs=false
--entryPoints.foo.observability.metrics=false
--entryPoints.foo.observability.tracing=false
```

---

## Helm Chart Note
The Helm chart creates these entryPoints by default: `web` (80), `websecure` (443), `traefik` (8080), `metrics` (9100). `web` and `websecure` are exposed by default via a Service. You can override everything via values or `additionalArguments`.

---

## Quick Reference (selected fields)
| Field | Description | Default |
|---|---|---|
| `address` | Listener address & protocol `[host]:port[/tcp\|/udp]` | — |
| `asDefault` | Include in default entryPoints list for HTTP/TCP routers | `false` |
| `allowACMEByPass` | Let custom routers handle ACME challenges | `false` |
| `reusePort` | Enable `SO_REUSEPORT` to share the same port across processes | `false` |
| `http2.maxConcurrentStreams` | Max concurrent HTTP/2 streams per connection | `250` |
| `http3.advertisedPort` | UDP port advertised for HTTP/3 `alt-svc` | (entryPoint port) |
| `forwardedHeaders.trustedIPs` | IPs/CIDRs trusted for `X-Forwarded-*` | — |
| `forwardedHeaders.insecure` | Always trust forwarded headers | `false` |
| `transport.respondingTimeouts.readTimeout` | Max duration to read the request | `60s` |
| `transport.respondingTimeouts.writeTimeout` | Max duration to write the response | `0s` |
| `transport.respondingTimeouts.idleTimeout` | Keep-alive idle timeout | `180s` |
| `transport.lifeCycle.requestAcceptGraceTimeout` | Accept requests before graceful stop | `0s` |
| `transport.lifeCycle.graceTimeOut` | Time to finish in-flight requests | `10s` |
| `proxyProtocol.{insecure,trustedIPs}` | Accept PROXY headers (globally or from list) | — |
| `http.redirections.entryPoint.{to,scheme,permanent,priority}` | Redirect all requests on this entryPoint | `scheme=https`, `permanent=false`, `priority=2147483646` |
| `http.encodeQuerySemicolons` | Encode unescaped `;` in query string | `false` |
| `http.sanitizePath` | Normalize/sanitize request paths | `false` |
| `http.middlewares` | Middlewares applied to routers on this entryPoint | — |
| `http.tls` | TLS options/resolver/SNI domains at entryPoint level | — |
| `udp.timeout` | Idle session timeout for UDP routing | `3s` |
| `observability.{accessLogs,metrics,tracing}` | Defaults for router observability | `true` |

---

_This cheat sheet aggregates the salient bits from the official docs for quick use in config files._
