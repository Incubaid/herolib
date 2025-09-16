# Comments API

A simple service for managing comments and discussions.

**Version:** 1.0.0

## Overview

The Comments API provides a straightforward way to manage comments, replies, and discussions. It supports threaded conversations, moderation features, and real-time updates.

### Base URL

```
http://localhost:8080/api/comments
```

---

## Authentication

All Comments API endpoints require authentication through the HeroServer Core API. Please refer to the [authentication documentation](./heroserver.md#authentication-flow) for details.

---

## Endpoints

### Create Comment

Create a new comment.

**Endpoint:** `POST /comments`

**Request Body:**

```json
{
  "content": "This is a great article! Thanks for sharing.",
  "author": "john_doe",
  "parent_id": null,
  "metadata": {
    "article_id": "article_123",
    "section": "introduction"
  }
}
```

**Response:**

```json
{
  "id": "comment_456789",
  "content": "This is a great article! Thanks for sharing.",
  "author": "john_doe",
  "parent_id": null,
  "metadata": {
    "article_id": "article_123",
    "section": "introduction"
  },
  "status": "published",
  "created_at": "2024-01-20T10:00:00Z",
  "updated_at": "2024-01-20T10:00:00Z",
  "replies_count": 0
}
```

### List Comments

Retrieve comments with optional filtering.

**Endpoint:** `GET /comments`

**Query Parameters:**

- `article_id` (optional): Filter by article ID
- `author` (optional): Filter by author
- `status` (optional): Filter by status (`published`, `pending`, `hidden`)
- `parent_id` (optional): Filter by parent comment ID (for replies)
- `limit` (optional): Maximum number of comments to return (default: 50)
- `offset` (optional): Number of comments to skip (default: 0)

**Response:**

```json
{
  "comments": [
    {
      "id": "comment_456789",
      "content": "This is a great article! Thanks for sharing.",
      "author": "john_doe",
      "parent_id": null,
      "metadata": {
        "article_id": "article_123",
        "section": "introduction"
      },
      "status": "published",
      "created_at": "2024-01-20T10:00:00Z",
      "updated_at": "2024-01-20T10:00:00Z",
      "replies_count": 2
    }
  ],
  "total": 1,
  "has_more": false
}
```

### Get Comment

Retrieve a specific comment by ID.

**Endpoint:** `GET /comments/{comment_id}`

**Response:** Comment object (same as create response)

### Update Comment

Update an existing comment.

**Endpoint:** `PUT /comments/{comment_id}`

**Request Body:**

```json
{
  "content": "Updated comment content",
  "status": "published"
}
```

**Response:** Updated comment object

### Delete Comment

Delete a comment (soft delete - marks as hidden).

**Endpoint:** `DELETE /comments/{comment_id}`

**Response:**

```json
{
  "message": "Comment deleted successfully"
}
```

### Reply to Comment

Create a reply to an existing comment.

**Endpoint:** `POST /comments/{comment_id}/replies`

**Request Body:**

```json
{
  "content": "Great point! I totally agree.",
  "author": "jane_smith"
}
```

**Response:** Reply comment object with `parent_id` set to the original comment

---

## Comment Status

Comments can have the following statuses:

- **published**: Comment is visible to all users
- **pending**: Comment is awaiting moderation
- **hidden**: Comment has been hidden by moderators

---

## Threading

The Comments API supports threaded conversations:

- **Top-level comments**: Have `parent_id` set to `null`
- **Replies**: Have `parent_id` set to the ID of the comment they're replying to
- **Nested replies**: Can reply to other replies, creating deep conversation threads

### Example Thread Structure

```
Comment A (parent_id: null)
├── Reply 1 (parent_id: comment_A_id)
│   └── Reply 1.1 (parent_id: reply_1_id)
└── Reply 2 (parent_id: comment_A_id)
```

---

## Moderation

### Moderate Comment

Update comment status for moderation.

**Endpoint:** `POST /comments/{comment_id}/moderate`

**Request Body:**

```json
{
  "status": "hidden",
  "reason": "inappropriate_content"
}
```

**Response:**

```json
{
  "id": "comment_456789",
  "status": "hidden",
  "moderated_at": "2024-01-20T15:30:00Z",
  "moderated_by": "moderator_123"
}
```

---

## Real-time Updates

The Comments API supports WebSocket connections for real-time comment updates:

**WebSocket Endpoint:** `ws://localhost:8080/api/comments/ws`

**Subscribe to Article Comments:**

```json
{
  "action": "subscribe",
  "article_id": "article_123"
}
```

**Receive New Comments:**

```json
{
  "type": "new_comment",
  "comment": {
    "id": "comment_789",
    "content": "New comment content",
    "author": "user_456",
    "created_at": "2024-01-20T16:00:00Z"
  }
}
```

---

## Error Handling

The Comments API uses standard HTTP status codes:

**400 Bad Request:**

```json
{
  "error": "invalid_request",
  "message": "Comment content cannot be empty",
  "details": {
    "field": "content",
    "code": "required"
  }
}
```

**404 Not Found:**

```json
{
  "error": "not_found",
  "message": "Comment not found",
  "details": {
    "comment_id": "comment_invalid"
  }
}
```

**403 Forbidden:**

```json
{
  "error": "forbidden",
  "message": "You can only edit your own comments",
  "details": {
    "comment_id": "comment_456789",
    "owner": "other_user"
  }
}
```

---

## Rate Limiting

The Comments API implements rate limiting to prevent spam:

- **Comment creation**: 10 comments per minute per user
- **Comment updates**: 20 updates per minute per user
- **Comment retrieval**: 100 requests per minute per user

---

## Examples

### Creating a Comment Thread

```bash
# Create top-level comment
curl -X POST http://localhost:8080/api/comments \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Great article about API design!",
    "author": "developer_123",
    "metadata": {"article_id": "api_design_101"}
  }'

# Reply to the comment
curl -X POST http://localhost:8080/api/comments/comment_456789/replies \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "I agree! The examples are very helpful.",
    "author": "reader_456"
  }'
```

### Retrieving Article Comments

```bash
curl "http://localhost:8080/api/comments?article_id=api_design_101&status=published" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Support

For questions and support:

- **Documentation**: [https://docs.heroserver.com/comments](https://docs.heroserver.com/comments)
- **GitHub**: [https://github.com/heroserver/comments-api](https://github.com/heroserver/comments-api)
- **Email**: comments-support@heroserver.com
