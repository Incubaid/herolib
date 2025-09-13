# Hero Models Examples

This directory contains example scripts demonstrating how to use the HeroDB models.

## Available Models

### Chat Models
- `heromodels_chat_group.vsh` - Example usage of ChatGroup model
- `heromodels_chat_message.vsh` - Example usage of ChatMessage model

### Other Models
- `heromodels_calendar.vsh` - Example usage of Calendar model
- `heromodels_calendar_event.vsh` - Example usage of CalendarEvent model
- `heromodels_calendar_event_simple.vsh` - Simple example of CalendarEvent model
- `heromodels_calendar_event_with_recurrence.vsh` - Example with recurrence rules
- `heromodels_comments.vsh` - Example usage of Comments helper
- `heromodels_group.vsh` - Example usage of Group model
- `heromodels_group_add_members.vsh` - Example adding members to a group
- `heromodels_group_relationships.vsh` - Example group relationships
- `heromodels_group_with_members.vsh` - Example group with members
- `heromodels_user.vsh` - Example usage of User model

## Running Examples

To run any example script, use the following command:

```bash
v -enable-globals run examples/hero/heromodels/<script_name>.vsh
```

For example:
```bash
v -enable-globals run examples/hero/heromodels/heromodels_chat_group.vsh
v -enable-globals run examples/hero/heromodels/heromodels_chat_message.vsh
```

## Chat Models Overview

### ChatGroup
Represents a chat channel or conversation with the following properties:
- `chat_type` - Type of chat (public_channel, private_channel, direct_message, group_message)
- `last_activity` - Unix timestamp of last activity
- `is_archived` - Whether the chat group is archived

### ChatMessage
Represents a message in a chat group with the following properties:
- `content` - The message content
- `chat_group_id` - Associated chat group ID
- `sender_id` - User ID of sender
- `parent_messages` - Referenced/replied messages
- `fs_files` - IDs of linked files
- `message_type` - Type of message (text, image, file, voice, video, system, announcement)
- `status` - Message status (sent, delivered, read, failed, deleted)
- `reactions` - Message reactions
- `mentions` - User IDs mentioned in message

## Implementation Details

The chat models are implemented in `lib/hero/heromodels/`:
- `chat_group.v` - Contains ChatGroup struct and related functionality
- `chat_message.v` - Contains ChatMessage struct and related functionality

Both models inherit from the base `db.Base` struct and implement the standard CRUD operations:
- `new()` - Create a new instance
- `set()` - Save to database
- `get()` - Retrieve from database
- `delete()` - Delete from database
- `exist()` - Check if exists in database
- `list()` - List all objects of this type
