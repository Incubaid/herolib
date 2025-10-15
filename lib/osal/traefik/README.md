# Traefik Module

This module provides functionality to manage Traefik configurations using Redis as a Key-Value store provider.

## Overview

The module allows you to:

- Define HTTP/HTTPS routes
- Configure backend services
- Set up middlewares
- Manage TLS certificates
- Store configurations in Redis using Traefik's KV store format

## Usage Example

```v
import incubaid.herolib.osal.core.traefik

fn main() ! {
    // Create a new Traefik configuration
    mut config := traefik.new_traefik_config()

    // Add a router with a service
    config.add_route(
        name: 'my-router'
        rule: 'Host(`example.com`)'
        service: 'my-service'
        middlewares: ['auth']
        tls: true
    )

    // Add the corresponding service
    config.add_service(
        name: 'my-service'
        load_balancer: traefik.LoadBalancerConfig{
            servers: [
                traefik.ServerConfig{url: 'http://localhost:8080'},
                traefik.ServerConfig{url: 'http://localhost:8081'}
            ]
        }
    )

    // Add a basic auth middleware
    config.add_middleware(
        name: 'auth'
        typ: 'basicAuth'
        settings: {
            'users': '["test:$apr1$H6uskkkW$IgXLP6ewTrSuBkTrqE8wj/"]'
        }
    )

    // Add TLS configuration
    config.add_tls(
        domain: 'example.com'
        cert_file: '/path/to/cert.pem'
        key_file: '/path/to/key.pem'
    )

    // Store configuration in Redis
    config.set()!
}
```

## Redis Key Structure

The module uses the following Redis key structure as per Traefik's KV store specification:

- `traefik/http/routers/<name>/*` - Router configurations
- `traefik/http/services/<name>/*` - Service configurations
- `traefik/http/middlewares/<name>/*` - Middleware configurations
- `traefik/tls/certificates` - TLS certificate configurations

## Configuration Types

### Router Configuration

```v
RouteConfig {
    name: string          // Router name
    rule: string          // Routing rule (e.g., "Host(`example.com`)")
    service: string       // Service to forward to
    middlewares: []string // Middleware chain
    priority: int         // Route priority
    tls: bool            // Enable TLS
}
```

### Service Configuration

```v
ServiceConfig {
    name: string
    load_balancer: LoadBalancerConfig
}

LoadBalancerConfig {
    servers: []ServerConfig
}

ServerConfig {
    url: string
}
```

### Middleware Configuration

```v
MiddlewareConfig {
    name: string
    typ: string                  // Middleware type
    settings: map[string]string  // Configuration settings
}
```

### TLS Configuration

```v
TLSConfig {
    domain: string      // Domain name
    cert_file: string   // Certificate file path
    key_file: string    // Private key file path
}
```

## References

- [Traefik Redis Provider Documentation](https://doc.traefik.io/traefik/reference/install-configuration/providers/kv/redis/)
- [Traefik KV Dynamic Configuration](https://doc.traefik.io/traefik/reference/dynamic-configuration/kv/)
