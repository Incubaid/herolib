module heromodels

import crypto.blake3
import json

// User represents a person in the system
@[heap]
pub struct User {
pub mut:
    id          string    // blake192 hash
    name        string
    email       string
    public_key  string    // for encryption/signing
    phone       string
    address     string
    avatar_url  string
    bio         string
    timezone    string
    created_at  i64
    updated_at  i64
    status      UserStatus
}

pub enum UserStatus {
    active
    inactive
    suspended
    pending
}

pub fn (mut u User) calculate_id() {
    content := json.encode(UserContent{
        name: u.name
        email: u.email
        public_key: u.public_key
        phone: u.phone
        address: u.address
        bio: u.bio
        timezone: u.timezone
        status: u.status
    })
    hash := blake3.sum256(content.bytes())
    u.id = hash.hex()[..48] // blake192 = first 192 bits = 48 hex chars
}

struct UserContent {
    name       string
    email      string
    public_key string
    phone      string
    address    string
    bio        string
    timezone   string
    status     UserStatus
}

pub fn new_user(name string, email string) User {
    mut user := User{
        name: name
        email: email
        created_at: time.now().unix_time()
        updated_at: time.now().unix_time()
        status: .active
    }
    user.calculate_id()
    return user
}