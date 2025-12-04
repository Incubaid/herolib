# Name.com Client Examples

This document contains HeroScript examples for the Name.com API client.

## Configuration

First, configure the client with your Name.com credentials:

```hero
!!namecomclient.configure
    name: 'default'
    url: 'https://api.name.com'
    username: 'your-username'
    token: 'your-api-token'
```

For sandbox/testing environment:

```hero
!!namecomclient.configure
    name: 'sandbox'
    url: 'https://api.dev.name.com'
    username: 'your-username-test'
    token: 'your-sandbox-token'
```

## List Domains

List all domains in your account:

```hero
!!namecomclient.domains_list
```

## List DNS Records

List all DNS records for a specific domain:

```hero
!!namecomclient.records_list
    domain: 'example.com'
```

## Set DNS Record

Create or update a DNS record. If a record with the same host and type exists, it will be updated. Otherwise, a new record is created.

### A Record Example

```hero
!!namecomclient.record_set
    domain: 'example.com'
    host: 'www'
    type: 'A'
    answer: '10.0.0.1'
    ttl: 300
```

### Apex/Root A Record

For apex records (root domain), use empty host or '@':

```hero
!!namecomclient.record_set
    domain: 'example.com'
    host: ''
    type: 'A'
    answer: '10.0.0.1'
    ttl: 300
```

### CNAME Record

```hero
!!namecomclient.record_set
    domain: 'example.com'
    host: 'blog'
    type: 'CNAME'
    answer: 'myblog.example.net'
    ttl: 300
```

### MX Record

```hero
!!namecomclient.record_set
    domain: 'example.com'
    host: ''
    type: 'MX'
    answer: 'mail.example.com'
    ttl: 300
    priority: 10
```

### TXT Record

```hero
!!namecomclient.record_set
    domain: 'example.com'
    host: ''
    type: 'TXT'
    answer: 'v=spf1 include:_spf.google.com ~all'
    ttl: 300
```

## Delete DNS Record

Delete a DNS record by host and type:

```hero
!!namecomclient.record_delete
    domain: 'example.com'
    host: 'www'
    type: 'A'
```

## Check Domain Availability

Check if domains are available for purchase:

```hero
!!namecomclient.check_availability
    domains: 'example.org, example.net, myawesomesite.com'
```

## Complete Example: Configure and Set A Record

This example shows a complete workflow to configure the client and set an A record:

```hero
!!namecomclient.configure
    url: 'https://api.name.com'
    username: 'myusername'
    token: 'my-api-token'

!!namecomclient.domains_list

!!namecomclient.record_set
    domain: 'mydomain.com'
    host: 'api'
    type: 'A'
    answer: '192.168.1.100'
    ttl: 300
```

## Available Actions

| Action | Description | Required Parameters |
|--------|-------------|---------------------|
| `namecomclient.configure` | Configure the client | `username`, `token` |
| `namecomclient.domains_list` | List all domains | - |
| `namecomclient.records_list` | List DNS records | `domain` |
| `namecomclient.record_set` | Create/update DNS record | `domain`, `answer` |
| `namecomclient.record_delete` | Delete DNS record | `domain` |
| `namecomclient.check_availability` | Check domain availability | `domains` |

## Parameters Reference

### record_set Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `domain` | string | required | Domain name (e.g., 'example.com') |
| `host` | string | '' | Hostname relative to domain (e.g., 'www', 'api', '' for apex) |
| `type` | string | 'A' | Record type: A, AAAA, ANAME, CNAME, MX, NS, SRV, TXT |
| `answer` | string | required | IP address or target depending on record type |
| `ttl` | u32 | 300 | Time to live in seconds (minimum 300) |
| `priority` | u32 | 0 | Priority for MX and SRV records |

## Running the Examples

You can run these examples using a V script:

```v
#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.playbook
import incubaid.herolib.clients.namecomclient

heroscript := "
!!namecomclient.configure
    url: 'https://api.name.com'
    username: 'your-username'
    token: 'your-token'

!!namecomclient.domains_list

!!namecomclient.record_set
    domain: 'yourdomain.com'
    host: 'test'
    type: 'A'
    answer: '10.0.0.1'
"

mut plbook := playbook.new(text: heroscript)!
namecomclient.play(mut plbook)!
```
