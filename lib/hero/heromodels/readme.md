
# HeroModels

HeroModels is a comprehensive data modeling and RPC API system for the HeroLib framework. It provides 13 different model types with consistent CRUD operations, efficient binary storage, and a clean JSON-RPC 2.0 API.

## Overview

HeroModels provides a unified approach to data management with:

- **13 Model Types**: User, Contact, Group, Project, Calendar, Message, and more
- **Consistent API**: All models support `set`, `get`, `update`, `delete`, and `list` operations
- **Efficient Storage**: Binary encoding with custom database backend
- **String-Based API**: User-friendly string timestamps and tags in RPC interface
- **Type Safety**: V language type system with proper validation

## Available Models

| Model | Description | Key Features |
|-------|-------------|--------------|
| `user` | User accounts and authentication | Profiles, roles, authentication |
| `contact` | Contact information management | Emails, phones, addresses |
| `group` | User groups and permissions | Hierarchical groups, member management |
| `project` | Project management | Issues, milestones, swimlanes |
| `project_issue` | Project issues and tasks | Status tracking, assignments |
| `calendar` | Calendar management | Events, scheduling |
| `calendar_event` | Calendar events | Meetings, appointments, reminders |
| `chat_group` | Chat groups and channels | Public/private channels |
| `chat_message` | Chat messages | Threading, attachments |
| `message` | General messaging | Email-like messaging system |
| `profile` | User profiles | Skills, experience, education |
| `planning` | Planning and scheduling | Resource planning, templates |
| `registration_desk` | Event registration | Attendee management, approval workflows |

## Args Pattern

HeroModels uses a consistent "Args" pattern for RPC operations:

### Input Format (Args)

- **String Timestamps**: Use human-readable format like `"2025-01-15 14:30"`
- **String Tags**: Use string arrays like `["tag1", "tag2", "tag3"]`
- **ID Field**: Include `id` field for update operations, omit for create operations

### Output Format (Response)

- **String Timestamps**: All timestamps returned as `"YYYY-MM-DD HH:mm"` format
- **String Tags**: All tags returned as sorted string arrays
- **Consistent Structure**: Same format across all models

### Internal Storage

- **Efficient Binary**: Timestamps stored as i64 Unix epochs
- **Hashed Tags**: Tags stored as u32 hash IDs for performance
- **Automatic Conversion**: Transparent conversion between formats

## API Usage Examples

### Create Operation (set)

```bash
curl 'http://localhost:8080/api/heromodels' \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "user.set",
    "params": {
      "name": "John Doe",
      "description": "Software Engineer",
      "email": "john@example.com",
      "tags": ["developer", "backend"],
      "securitypolicy": 1
    },
    "id": 1
  }'
```

**Response:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": 42
}
```

### Update Operation (update)

```bash
curl 'http://localhost:8080/api/heromodels' \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "user.update",
    "params": {
      "id": 42,
      "name": "John Smith",
      "description": "Senior Software Engineer",
      "email": "john.smith@example.com",
      "tags": ["senior", "fullstack", "lead"],
      "securitypolicy": 2
    },
    "id": 2
  }'
```

**Response:**

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "id": 42,
    "name": "John Smith",
    "description": "Senior Software Engineer",
    "created_at": "2025-01-15 10:30",
    "updated_at": "2025-01-15 14:45",
    "email": "john.smith@example.com",
    "tags": ["fullstack", "lead", "senior"],
    "securitypolicy": 2
  }
}
```

### Get Operation (get)

```bash
curl 'http://localhost:8080/api/heromodels' \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "user.get",
    "params": 42,
    "id": 3
  }'
```

### Delete Operation (delete)

```bash
curl 'http://localhost:8080/api/heromodels' \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "user.delete",
    "params": 42,
    "id": 4
  }'
```

## Key Differences: Set vs Update

| Operation | Purpose | ID Required | Response |
|-----------|---------|-------------|----------|
| `set` | Create new record | No (ignored if provided) | Returns new ID |
| `update` | Modify existing record | Yes (required) | Returns full updated object |

## Implementation Pattern

All models follow the same clean implementation pattern:

### 1. Single Arg Struct

```v
@[params]
pub struct ModelArg {
pub mut:
    id             u32      // Required for update, ignored for set
    name           string
    description    string
    // ... other fields ...
    tags           []string
    securitypolicy u32
}
```

### 2. Clean Update Method

```v
pub fn (mut self DBModel) update(args ModelArg) !Model {
    // Create new object with all the updated data
    mut updated := self.new(args)!
    // Set the ID to update existing record
    updated.id = args.id
    // Use set method which will replace the existing record
    return self.set(updated)!
}
```

### 3. RPC Handler with Validation

```v
'update' {
    args := db.decode_generic[ModelArg](params)!
    if args.id == 0 {
        return new_error(rpcid, code: 400, message: 'ID is required for update operation')
    }
    o := f.model.update(args)!
    response_json := converter.convert_model_to_response(o)!
    return new_response(rpcid, response_json)
}
```

## Performance Features

- **Binary Storage**: Efficient custom binary encoding
- **Tag Hashing**: Fast tag lookups using hash IDs
- **Lazy Loading**: Related objects loaded on demand
- **Connection Pooling**: Redis integration for caching
- **Batch Operations**: Support for bulk operations

## Error Handling

The API returns standard JSON-RPC 2.0 error responses:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": 400,
    "message": "ID is required for update operation"
  }
}
```

Common error codes:

- `400`: Bad Request (missing required fields)
- `404`: Not Found (record doesn't exist)
- `500`: Internal Server Error

## Development

### Running the Server

```bash
# Start the heromodels server
/Users/mahmoud/code/github/freeflowuniverse/herolib/examples/hero/heromodels/heroserver_example.vsh
```

### Testing

```bash
# Run model tests
v -enable-globals -no-skip-unused test lib/hero/heromodels/user_test.v
v -enable-globals -no-skip-unused test lib/hero/heromodels/contact_test.v
```

### API Discovery

```bash
# Get OpenRPC specification
curl 'http://localhost:8080/json/heromodels'

# View documentation
curl 'http://localhost:8080/doc/heromodels'
```
