// File: lib/clients/namecomclient/readme.md

# namecomclient

This library provides a client for interacting with the Name.com API v4.

## Configuration

You can configure the client using a HeroScript file:

```hero
!!namecomclient.configure
    name: 'default' // optional, 'default' is the default instance name
    url: 'https://api.name.com'  // production URL, use 'https://api.dev.name.com' for sandbox
    username: 'your-username'
    token: 'your-api-token'
```

## Usage Example

Here's how to get the client and use its methods.

```v
import incubaid.herolib.clients.namecomclient
import incubaid.herolib.core.base

fn main() ! {
    // Make sure hero is initialized
    base.init()!

    // Example configuration (can also be loaded from file)
    heroscript_config := "!!namecomclient.configure url:'https://api.name.com' username:'myuser' token:'...your_token...'"
    mut plbook := playbook.new(text: heroscript_config)!
    namecomclient.play(mut plbook)!

    // Get the default configured client
    mut client := namecomclient.get()!

    // Test connection
    hello := client.hello()!
    println('Connected as: ${hello.username}')

    // List all domains
    domains := client.list_domains()!
    println('Found ${domains.len} domains:')
    for domain in domains {
        println('- ${domain.domain_name} (expires: ${domain.expire_date})')
    }

    // Get DNS records for a domain
    records := client.list_records('example.com')!
    println('Found ${records.len} DNS records:')
    for record in records {
        println('  ${record.host}.${record.domain_name} ${record.record_type} ${record.answer}')
    }

    // Create a new A record
    new_record := client.create_record('example.com', namecomclient.CreateRecordRequest{
        host: 'www'
        record_type: 'A'
        answer: '10.0.0.1'
        ttl: 300
    })!
    println('Created record with ID: ${new_record.id}')

    // Check domain availability
    results := client.check_availability(['example.org', 'example.net'])!
    for result in results {
        status := if result.purchasable { 'available' } else { 'taken' }
        println('${result.domain_name}: ${status}')
    }
}
```

## API Reference

### Domain Operations

- `list_domains()` - List all domains in the account
- `get_domain(domain_name)` - Get details for a specific domain
- `lock_domain(domain_name)` - Lock a domain to prevent transfers
- `unlock_domain(domain_name)` - Unlock a domain to allow transfers
- `enable_autorenew(domain_name)` - Enable auto-renewal
- `disable_autorenew(domain_name)` - Disable auto-renewal
- `enable_whois_privacy(domain_name)` - Enable WHOIS privacy
- `disable_whois_privacy(domain_name)` - Disable WHOIS privacy
- `set_nameservers(domain_name, nameservers)` - Set nameservers for a domain
- `set_contacts(domain_name, contacts)` - Set contacts for a domain
- `check_availability(domain_names)` - Check if domains are available
- `search(keyword)` - Search for available domains

### DNS Record Operations

- `list_records(domain_name)` - List all DNS records for a domain
- `get_record(domain_name, record_id)` - Get a specific DNS record
- `create_record(domain_name, record)` - Create a new DNS record
- `update_record(domain_name, record_id, record)` - Update a DNS record
- `delete_record(domain_name, record_id)` - Delete a DNS record

## Environments

- **Production**: `https://api.name.com`
- **Sandbox**: `https://api.dev.name.com`

## HeroScript Actions

The client supports the following HeroScript actions:

### Configure Client

```hero
!!namecomclient.configure
    url: 'https://api.name.com'
    username: 'your-username'
    token: 'your-api-token'
```

### List Domains

```hero
!!namecomclient.domains_list
```

### List DNS Records

```hero
!!namecomclient.records_list
    domain: 'example.com'
```

### Set DNS Record (Create or Update)

```hero
!!namecomclient.record_set
    domain: 'example.com'
    host: 'www'
    type: 'A'
    answer: '10.0.0.1'
    ttl: 300
    priority: 0
```

### Delete DNS Record

```hero
!!namecomclient.record_delete
    domain: 'example.com'
    host: 'www'
    type: 'A'
```

### Check Domain Availability

```hero
!!namecomclient.check_availability
    domains: 'example.org, example.net'
```

## Tips

- Get your API token from your Name.com account settings
- Use the sandbox environment for testing
- API rate limits: 20 requests/second, 3,000 requests/hour
- See the API docs: https://www.name.com/api-docs
- See examples at: `examples/clients/namecom/`
