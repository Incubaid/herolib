module models

import time

// Contact represents a person associated with a customer or organization
pub struct Contact {
pub mut:
	id         int
	name       string @[required]
	email      string
	phone      string
	mobile     string
	role       string
	department string
	type       ContactType
	is_primary bool
	notes      string
	created_at time.Time
	updated_at time.Time
}

// Address represents a physical address
pub struct Address {
pub mut:
	id          int
	type        AddressType
	label       string // e.g., "Main Office", "Warehouse"
	street      string
	street2     string // Additional address line
	city        string
	state       string
	postal_code string
	country     string
	is_primary  bool
	created_at  time.Time
	updated_at  time.Time
}

// TimeEntry represents time spent on tasks or projects
pub struct TimeEntry {
pub mut:
	id          int
	user_id     int @[required]
	task_id     int
	project_id  int
	start_time  time.Time
	end_time    time.Time
	duration    f32 // Hours (calculated or manual)
	description string
	type        TimeEntryType
	billable    bool
	hourly_rate f64
	created_at  time.Time
	updated_at  time.Time
}

// Comment represents a comment on tasks, issues, or other entities
pub struct Comment {
pub mut:
	id          int
	author_id   int    @[required]
	content     string @[required]
	timestamp   time.Time
	is_internal bool // Internal comments not visible to clients
	is_edited   bool
	edited_at   time.Time
	parent_id   int // For threaded comments
}

// Attachment represents a file attached to an entity
pub struct Attachment {
pub mut:
	id            int
	filename      string @[required]
	original_name string
	file_path     string @[required]
	file_size     i64
	mime_type     string
	uploaded_by   int // User ID
	uploaded_at   time.Time
	description   string
	is_public     bool // Whether clients can see this attachment
}

// Condition represents a requirement that must be met for a milestone
pub struct Condition1 {
pub mut:
	id             int
	milestone_id   int    @[required]
	description    string @[required]
	status         ConditionStatus
	verification   string // How to verify this condition is met
	responsible_id int    // User ID responsible for this condition
	due_date       time.Time
	completed_at   time.Time
	notes          string
	created_at     time.Time
	updated_at     time.Time
}

// Message represents a chat message
pub struct Message1 {
pub mut:
	id           int
	chat_id      int    @[required]
	sender_id    int    @[required]
	content      string @[required]
	timestamp    time.Time
	message_type MessageType
	attachments  []Attachment
	reactions    []Reaction
	thread_id    int // For threaded conversations
	is_edited    bool
	edited_at    time.Time
	mentions     []int // User IDs mentioned in the message
}

// Reaction represents an emoji reaction to a message
pub struct Reaction1 {
pub mut:
	id         int
	message_id int    @[required]
	user_id    int    @[required]
	emoji      string @[required]
	timestamp  time.Time
}

// Notification represents a system notification
pub struct Notification {
pub mut:
	id          int
	user_id     int    @[required]
	title       string @[required]
	message     string @[required]
	type        NotificationType
	entity_type string // e.g., "task", "project", "issue"
	entity_id   int
	is_read     bool
	created_at  time.Time
	read_at     time.Time
}

// NotificationType for different kinds of notifications
pub enum NotificationType {
	info
	warning
	error
	success
	task_assigned
	task_completed
	deadline_approaching
	milestone_reached
	comment_added
	mention
}

// Reminder for agenda items
pub struct Reminder {
pub mut:
	id        int
	agenda_id int @[required]
	user_id   int @[required]
	remind_at time.Time
	message   string
	is_sent   bool
	sent_at   time.Time
}

// RecurrenceRule for recurring agenda items
pub struct PlannerRecurrenceRule {
pub mut:
	frequency    RecurrenceFrequency
	interval     int = 1 // Every N frequency units
	end_date     time.Time
	count        int   // Number of occurrences
	days_of_week []int // 0=Sunday, 1=Monday, etc.
	day_of_month int
}

// RecurrenceFrequency for agenda recurrence
pub enum RecurrenceFrequency {
	none
	daily
	weekly
	monthly
	yearly
}

// UserPreferences for user-specific settings
pub struct UserPreferences {
pub mut:
	timezone            string = 'UTC'
	date_format         string = 'YYYY-MM-DD'
	time_format         string = '24h'
	language            string = 'en'
	theme               string = 'light'
	notifications_email bool   = true
	notifications_push  bool   = true
	default_view        string = 'kanban'
}

// ProjectRole represents a user's role in a specific project
pub struct ProjectRole {
pub mut:
	user_id     int    @[required]
	project_id  int    @[required]
	role        string @[required] // e.g., "lead", "developer", "tester"
	permissions []string // Specific permissions for this project
	assigned_at time.Time
}

// TaskDependency represents dependencies between tasks
pub struct TaskDependency {
pub mut:
	id              int
	task_id         int @[required] // The dependent task
	depends_on_id   int @[required] // The task it depends on
	dependency_type DependencyType
	created_at      time.Time
}

// DependencyType for task dependencies
pub enum DependencyType {
	finish_to_start  // Most common: predecessor must finish before successor starts
	start_to_start   // Both tasks start at the same time
	finish_to_finish // Both tasks finish at the same time
	start_to_finish  // Successor can't finish until predecessor starts
}

// Label for flexible categorization
pub struct Label {
pub mut:
	id          int
	name        string @[required]
	color       string // Hex color code
	description string
	created_at  time.Time
}
