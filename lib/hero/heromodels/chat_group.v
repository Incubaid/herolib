module heromodels

import time
import crypto.blake3
import json

// ChatGroup represents a chat channel or conversation
@[heap]
pub struct ChatGroup {
pub mut:
    id          string     // blake192 hash
    name        string
    description string
    group_id    string     // Associated group for permissions
    chat_type   ChatType
    messages    []string   // IDs of chat messages
    created_at  i64
    updated_at  i64
    last_activity i64
    is_archived bool
    tags        []string
}

pub enum ChatType {
    public_channel
    private_channel
    direct_message
    group_message
}

pub fn (mut c ChatGroup) calculate_id() {
    content := json.encode(ChatGroupContent{
        name: c.name
        description: c.description
        group_id: c.group_id
        chat_type: c.chat_type
        is_archived: c.is_archived
        tags: c.tags
    })
    hash := blake3.sum256(content.bytes())
    c.id = hash.hex()[..48]
}

struct ChatGroupContent {
    name        string
    description string
    group_id    string
    chat_type   ChatType
    is_archived bool
    tags        []string
}

pub fn new_chat_group(name string, group_id string, chat_type ChatType) ChatGroup {
    mut chat_group := ChatGroup{
        name: name
        group_id: group_id
        chat_type: chat_type
        created_at: time.now().unix()
        updated_at: time.now().unix()
        last_activity: time.now().unix()
    }
    chat_group.calculate_id()
    return chat_group
}