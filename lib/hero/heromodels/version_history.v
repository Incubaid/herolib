module heromodels

// VersionHistory tracks the evolution of objects by their blake192 IDs
@[heap]
pub struct VersionHistory {
pub mut:
    current_id   string // blake192 hash of current version
    previous_id  string // blake192 hash of previous version
    next_id      string // blake192 hash of next version (if exists)
    object_type  string // Type of object (User, Group, etc.)
    change_type  ChangeType
    changed_by   string // User ID who made the change
    changed_at   i64    // Unix timestamp
    change_notes string // Optional description of changes
}

pub enum ChangeType {
    create
    update
    delete
    restore
}

pub fn new_version_history(current_id string, previous_id string, object_type string, change_type ChangeType, changed_by string) VersionHistory {
    return VersionHistory{
        current_id: current_id
        previous_id: previous_id
        object_type: object_type
        change_type: change_type
        changed_by: changed_by
        changed_at: time.now().unix_time()
    }
}

// Database indexes needed:
// - Index on current_id for fast lookup
// - Index on previous_id for walking backward
// - Index on next_id for walking forward
// - Index on object_type for filtering by type
// - Index on changed_by for user activity tracking