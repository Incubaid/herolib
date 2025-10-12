# HTTPConnection Module

The `HTTPConnection` module provides a robust HTTP client for Vlang, supporting JSON, custom headers, retries, and caching.

## Key Features

- Type-safe JSON methods
- Custom headers
- Retry mechanism
- Caching
- URL encoding

## Basic Usage

```v
import incubaid.herolib.core.httpconnection

// Create a new HTTP connection
mut conn := httpconnection.new(
    name: 'my_api_client'
    url: 'https://api.example.com'
    retry: 3 // Number of retries for failed requests
    cache: true // Enable caching
)!
```

## Integration with Management Classes

To integrate `HTTPConnection` into a management class (e.g., `HetznerManager`), use a method to lazily initialize and return the connection:

```v
// Example: HetznerManager
pub fn (mut h HetznerManager) connection() !&httpconnection.HTTPConnection {
 mut c := h.conn or {
  mut c2 := httpconnection.new(
   name:  'hetzner_${h.name}'
   url:   h.baseurl
   cache: true
   retry: 3
  )!
  c2.basic_auth(h.user, h.password)
  c2
 }
 return c
}
```

## Examples

### GET Request with JSON Response

```v
struct User {
    id    int
    name  string
    email string
}

user := conn.get_json_generic[User](
    prefix: 'users/1'
)!
```

### POST Request with JSON Data

```v
struct NewUserResponse {
    id int
    status string
}

new_user_resp := conn.post_json_generic[NewUserResponse](
    prefix: 'users'
    params: {
        'name': 'Jane Doe'
        'email': 'jane@example.com'
    }
)!
```

### Custom Headers

Set default headers or add them per request:

```v
import net.http { Header }

// Set default header
conn.default_header = http.new_header(key: .authorization, value: 'Bearer your-token')

// Add custom header for a specific request
response := conn.get_json(
    prefix: 'protected/resource'
    header: http.new_header(key: .content_type, value: 'application/json')
)!
```

### Error Handling

Methods return a `Result` type for error handling:

```v
user := conn.get_json_generic[User](
    prefix: 'users/1'
) or {
    println('Error fetching user: ${err}')
    return
}
