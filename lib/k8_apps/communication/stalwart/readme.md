# Stalwart Mail Server K8s Installer

Deploy **Stalwart Mail** (SMTP/IMAP/POP3/Sieve) + **JMAP/CalDAV/CardDAV/UI** on a k3s cluster.

## Architecture

```
(Internet) ── HTTPS ──▶ TFGW ── HTTP ──▶ Traefik Ingress ──▶ Service (stalwart-http:80) ─▶ Pod (JMAP/DAV/UI :8080)

Mail clients ── Mycelium IPv6 TCP ──▶ ServiceLB (stalwart-mail: 25/465/587/143/993/110/995/4190 DNAT) ─▶ Pod (Stalwart)
```

## Features

- **TFGW** generates an HTTPS FQDN (`https://<hostname>.gent01.grid.tf`) for web access
- **Traefik Ingress** for all web protocols (JMAP/DAV/UI on :8080 inside the pod)
- **k3s ServiceLB (klipper-lb)** as a **dual-stack** LoadBalancer for mail TCP ports
- **ConfigMap** with embedded `config.toml` and **PVC** for Stalwart data/logs

## Usage

```v
import incubaid.herolib.k8_apps.communication.stalwart

// Create installer instance
mut installer := stalwart.get(
    name:   'mymail'
    create: true
)!

// Optional: customize settings
installer.hostname = 'mymail'           // TFGW hostname
installer.admin_user = 'admin'          // Admin username
installer.admin_password = 'secure123'  // Admin password
installer.storage_size = '50Gi'         // PVC storage size
installer.log_level = 'info'            // Log level

// Install
installer.install()!

// Destroy when done
// installer.destroy()!
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `name` | `stalwart` | Instance name |
| `hostname` | `{name}mail` | TFGW hostname |
| `namespace` | `{name}stalwartns` | Kubernetes namespace |
| `admin_user` | `admin` | Admin username |
| `admin_password` | `changeme123` | Admin password |
| `storage_size` | `20Gi` | PVC storage size |
| `http_port` | `8080` | HTTP port for web UI |
| `log_level` | `info` | Log level (info, debug, warn, error) |

## Mail Ports

The LoadBalancer service exposes these ports:

| Port | Protocol | Description |
|------|----------|-------------|
| 25 | SMTP | Mail submission |
| 465 | SMTPS | SMTP over TLS |
| 587 | Submission | Mail submission (STARTTLS) |
| 143 | IMAP | IMAP access |
| 993 | IMAPS | IMAP over TLS |
| 110 | POP3 | POP3 access |
| 995 | POP3S | POP3 over TLS |
| 4190 | ManageSieve | Sieve filter management |

