module heromodels

import crypto.blake3
import json

// ChatMessage represents a message in a chat group
@[heap]
pub struct ChatMessage {
pub mut:
    id           string           // blake192 hash
    content      string
    chat_group_id string          // Associated chat group
    sender_id    string           // User ID of sender
    parent_messages []MessageLink // Referenced/replied messages
    fs_files     []string         // IDs of linked files
    message_type MessageType
    status       MessageStatus
    created_at   i64
    updated_at   i64
    edited_at    i64
    deleted_at   i64
    reactions    []MessageReaction
    mentions     []string         // User IDs mentioned in message
    tags         []string
}

pub struct MessageLink {
pub mut:
    message_id string
    link_type  MessageLinkType
}

pub enum MessageLinkType {
    reply
    reference
    forward
    quote
}

pub enum MessageType {
    text
    image
    file
    voice
    video
    system
    announcement
}

pub enum MessageStatus {
    sent
    delivered
    read
    failed
    deleted
}

pub struct MessageReaction {
pub mut:
    user_id   string
    emoji     string
    timestamp i64
}

pub fn (mut m ChatMessage) calculate_id() {
    content := json.encode(MessageContent{
        content: m.content
        chat_group_id: m.chat_group_id
        sender_id: m.sender_id
        parent_messages: m.parent_messages
        fs_files: m.fs_files
        message_type: m.message_type
        mentions: m.mentions
        tags: m.tags
    })
    hash := blake3.sum256(content.bytes())
    m.id = hash.hex()[..48]
}

struct MessageContent {
    content         string
    chat_group_id   string
    sender_id       string
    parent_messages []MessageLink
    fs_files        []string
    message_type    MessageType
    mentions        []string
    tags            []string
}

pub fn new_chat_message(content string, chat_group_id string, sender_id string) ChatMessage {
    mut message := ChatMessage{
        content: content
        chat_group_id: chat_group_id
        sender_id: sender_id
        message_type: .text
        status: .sent
        created_at: time.now().unix_time()
        updated_at: time.now().unix_time()
    }
    message.calculate_id()
    return message
}