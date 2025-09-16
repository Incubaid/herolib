# HeroServer Core API Documentation

The core HeroServer API provides authentication and system endpoints that are required before accessing any registered APIs.

**Version:** 1.0.0

## Overview

The HeroServer Core API handles user authentication using Ed25519 public key cryptography and provides system information endpoints. All other APIs require authentication through these core endpoints.

### Base URL

```
http://localhost:8080
```

---

## Authentication Endpoints

### Register Public Key

Register your Ed25519 public key with the server to enable authentication.

**Endpoint:** `POST /register`

**Request Body:**

```json
{
  "public_key": "your_ed25519_public_key_in_base64"
}
```

**Response:**

```json
{
  "status": "success",
  "message": "Public key registered successfully"
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/register \
  -H "Content-Type: application/json" \
  -d '{"public_key": "MCowBQYDK0OAQEiA..."}'
```

---

### Request Authentication Challenge

Request a challenge that must be signed with your private key.

**Endpoint:** `POST /authreq`

**Request Body:**

```json
{
  "public_key": "your_ed25519_public_key_in_base64"
}
```

**Response:**

```json
{
  "challenge": "base64_encoded_challenge_to_sign"
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/authreq \
  -H "Content-Type: application/json" \
  -d '{"public_key": "MCowBQYDK0OAQEiA..."}'
```

---

### Authenticate with Signed Challenge

Submit the signed challenge to receive a session key for API access.

**Endpoint:** `POST /auth`

**Request Body:**

```json
{
  "public_key": "your_ed25519_public_key_in_base64",
  "signature": "base64_encoded_signature_of_challenge"
}
```

**Response:**

```json
{
  "session_key": "your_session_key_for_api_calls",
  "expires_at": "2024-01-01T12:00:00Z"
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/auth \
  -H "Content-Type: application/json" \
  -d '{
    "public_key": "MCowBQYDK0OAQEiA...",
    "signature": "signature_of_challenge..."
  }'
```

---

## Documentation Endpoints

### Documentation Index

View all available APIs and their documentation.

**Endpoint:** `GET /docs`

**Response:** HTML page with list of all registered APIs

**Example:**

```bash
curl http://localhost:8080/docs
```

---

### API-Specific Documentation

View documentation for a specific registered API.

**Endpoint:** `GET /docs/{api_name}`

**Parameters:**

- `api_name`: The name of the registered API (e.g., "comments")

**Response:** HTML documentation page for the specified API

**Example:**

```bash
curl http://localhost:8080/docs/comments
```

---

## API Access Endpoints

### Call Registered API Methods

Once authenticated, call methods on registered APIs using JSON-RPC 2.0.

**Endpoint:** `POST /api/{api_name}`

**Headers:**

```
Content-Type: application/json
Authorization: your_session_key_here
```

**Request Body (JSON-RPC 2.0):**

```json
{
  "jsonrpc": "2.0",
  "method": "method_name",
  "params": {
    "param1": "value1",
    "param2": "value2"
  },
  "id": 1
}
```

**Response:**

```json
{
  "jsonrpc": "2.0",
  "result": {
    "data": "method_response_data"
  },
  "id": 1
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/api/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: your_session_key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "add_comment",
    "params": {"content": "Hello World!"},
    "id": 1
  }'
```

---

## Error Handling

### Authentication Errors

| Code | Message | Description |
|------|---------|-------------|
| `400` | Bad Request | Invalid request format or missing required fields |
| `401` | Unauthorized | Invalid or missing authentication credentials |
| `403` | Forbidden | Valid credentials but insufficient permissions |
| `404` | Not Found | Requested endpoint or resource not found |
| `500` | Internal Server Error | Server-side error occurred |

### JSON-RPC Errors

| Code | Message | Description |
|------|---------|-------------|
| `-32700` | Parse error | Invalid JSON was received |
| `-32600` | Invalid Request | The JSON sent is not a valid Request object |
| `-32601` | Method not found | The method does not exist |
| `-32602` | Invalid params | Invalid method parameter(s) |
| `-32603` | Internal error | Internal JSON-RPC error |

---

## Security Considerations

### Ed25519 Key Management

- **Generate secure keys**: Use a cryptographically secure random number generator
- **Store private keys safely**: Never share or transmit private keys
- **Rotate keys regularly**: Consider periodic key rotation for enhanced security

### Session Management

- **Session expiration**: Session keys have a limited lifetime
- **Secure transmission**: Always use HTTPS in production
- **Key storage**: Store session keys securely on the client side

### Rate Limiting

- **Authentication endpoints**: Limited to prevent brute force attacks
- **API endpoints**: Rate limited per session to ensure fair usage
- **Documentation endpoints**: Publicly accessible but may have basic rate limits

---

## Complete Authentication Flow Example

Here's a complete example of the authentication flow using curl:

```bash
# 1. Register your public key
curl -X POST http://localhost:8080/register \
  -H "Content-Type: application/json" \
  -d '{"public_key": "your_public_key_here"}'

# 2. Request authentication challenge
CHALLENGE=$(curl -X POST http://localhost:8080/authreq \
  -H "Content-Type: application/json" \
  -d '{"public_key": "your_public_key_here"}' | jq -r '.challenge')

# 3. Sign the challenge (using your preferred signing method)
SIGNATURE=$(echo "$CHALLENGE" | your_signing_tool)

# 4. Authenticate and get session key
SESSION_KEY=$(curl -X POST http://localhost:8080/auth \
  -H "Content-Type: application/json" \
  -d "{\"public_key\": \"your_public_key_here\", \"signature\": \"$SIGNATURE\"}" | jq -r '.session_key')

# 5. Use session key for API calls
curl -X POST http://localhost:8080/api/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: $SESSION_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "add_comment",
    "params": {"content": "Hello from HeroServer!"},
    "id": 1
  }'
```
