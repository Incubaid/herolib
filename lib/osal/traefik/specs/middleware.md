Here’s the updated Markdown document, now enriched with direct links to the individual middleware reference pages to help you navigate easily.

---

# Traefik Proxy — Middlewares (Overview)

Middlewares are components you attach to **routers** to tweak requests before they reach a **service** (or to tweak responses before they reach clients). They can modify paths and headers, handle redirections, add authentication, rate-limit, and more. Multiple middlewares using the same protocol can be **chained** to fit complex scenarios. ([Overview page]({doc.traefik.io/traefik/middlewares/overview/})) ([Traefik Docs][1], [Traefik Docs][2])

> **Note — Provider Namespace**
> The “Providers Namespace” concept from Configuration Discovery also applies to middlewares (e.g., `foo@docker`, `bar@file`). ([Traefik Docs][1], [Traefik Docs][3])

---

## Configuration Examples

Examples showing how to **define** a middleware and **attach** it to a router across different providers. ([Traefik Docs][2])

<details>
<summary>Docker & Swarm (labels)</summary>

```yaml
whoami:
  image: traefik/whoami
  labels:
    - "traefik.http.middlewares.foo-add-prefix.addprefix.prefix=/foo"
    - "traefik.http.routers.router1.middlewares=foo-add-prefix@docker"
```

</details>

<details>
<summary>Kubernetes CRD (IngressRoute)</summary>

```yaml
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: stripprefix
spec:
  stripPrefix:
    prefixes:
      - /stripit

---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroute
spec:
  routes:
    - match: Host(`example.com`)
      kind: Rule
      services:
        - name: my-svc
          port: 80
      middlewares:
        - name: stripprefix
```

</details>

<details>
<summary>Consul Catalog (labels)</summary>

```text
"traefik.http.middlewares.foo-add-prefix.addprefix.prefix=/foo"
"traefik.http.routers.router1.middlewares=foo-add-prefix@consulcatalog"
```

</details>

<details>
<summary>File Provider (YAML)</summary>

```yaml
http:
  routers:
    router1:
      rule: "Host(`example.com`)"
      service: myService
      middlewares:
        - "foo-add-prefix"

  middlewares:
    foo-add-prefix:
      addPrefix:
        prefix: "/foo"

  services:
    myService:
      loadBalancer:
        servers:
          - url: "http://127.0.0.1:80"
```

</details>

<details>
<summary>File Provider (TOML)</summary>

```toml
[http.routers.router1]
rule = "Host(`example.com`)"
service = "myService"
middlewares = ["foo-add-prefix"]

[http.middlewares.foo-add-prefix.addPrefix]
prefix = "/foo"

[http.services.myService.loadBalancer.servers]
url = "http://127.0.0.1:80"
```

</details>

---

## Available Middlewares

**HTTP Middlewares** — the complete list is detailed in the HTTP middlewares section:
AddPrefix, BasicAuth, Buffering, Chain, CircuitBreaker, Compress, ContentType, DigestAuth, Errors, ForwardAuth, GrpcWeb, Headers, IPAllowList / IPWhiteList, InFlightReq, PassTLSClientCert, RateLimit, RedirectRegex, RedirectScheme, ReplacePath, ReplacePathRegex, Retry, StripPrefix, StripPrefixRegex. ([Traefik Docs][4])

**TCP Middlewares** — covered in the TCP middlewares section:
InFlightConn, IPAllowList / IPWhiteList. ([Traefik Docs][5])

---

## Middleware Reference Links

Below are direct links to documentation for some of the most commonly used middlewares:

* **[AddPrefix](https://doc.traefik.io/traefik/middlewares/http/addprefix/)** — prepends a path segment to requests ([Traefik Docs][6], [Traefik Docs][7])
* **[BasicAuth](https://doc.traefik.io/traefik/middlewares/http/basicauth/)** — adds basic HTTP authentication ([Traefik Docs][8])
* **[IPAllowList (HTTP)](https://doc.traefik.io/traefik/middlewares/http/ipallowlist/)** — allows access only from specified IPs ([Traefik Docs][9])
* **[IPWhiteList (TCP)](https://doc.traefik.io/traefik/middlewares/tcp/ipwhitelist/)** — deprecated way to white-list TCP client IPs; prefer IPAllowList ([Traefik Docs][5])

(These are just a few examples—feel free to ask for more specific middleware links if needed.)

---

### Optional: Full Document Outline

If you’d like the full reference structure in Markdown, here's a possible outline to expand further:

```
# Traefik Middlewares Reference

## Overview (link)
- Overview of Middlewares

## Configuration Examples
- Docker / Swarm
- Kubernetes CRD
- Consul Catalog
- File (YAML & TOML)

## HTTP Middlewares
- AddPrefix — [AddPrefix link]
- BasicAuth — [BasicAuth link]
- Buffering — [Buffering link]
- Chain — [Chain link]
- ... (and so on)

## TCP Middlewares
- IPAllowList (TCP) — [IPAllowList TCP link]
- (Any other TCP middleware)

## Additional Resources
- Kubernetes CRD Middleware — [CRD link]
- Routers and middleware chaining — [Routers link]
- Dynamic configuration via File provider — [File provider link]
```

[1]: https://doc.traefik.io/traefik/v2.2/middlewares/overview/?utm_source=chatgpt.com "Middlewares"
[2]: https://doc.traefik.io/traefik/middlewares/overview/?utm_source=chatgpt.com "Traefik Proxy Middleware Overview"
[3]: https://doc.traefik.io/traefik/reference/dynamic-configuration/file/?utm_source=chatgpt.com "Traefik File Dynamic Configuration"
[4]: https://doc.traefik.io/traefik/middlewares/http/overview/?utm_source=chatgpt.com "Traefik Proxy HTTP Middleware Overview"
[5]: https://doc.traefik.io/traefik/middlewares/tcp/ipwhitelist/?utm_source=chatgpt.com "Traefik TCP Middlewares IPWhiteList"
[6]: https://doc.traefik.io/traefik/routing/routers/?utm_source=chatgpt.com "Traefik Routers Documentation"
[7]: https://doc.traefik.io/traefik/middlewares/http/addprefix/?utm_source=chatgpt.com "Traefik AddPrefix Documentation"
[8]: https://doc.traefik.io/traefik/middlewares/http/basicauth/?utm_source=chatgpt.com "Traefik BasicAuth Documentation"
[9]: https://doc.traefik.io/traefik/middlewares/http/ipallowlist/?utm_source=chatgpt.com "Traefik HTTP Middlewares IPAllowList"
