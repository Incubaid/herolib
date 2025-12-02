module meta

// Announcement bar config structure
pub struct Announcement {
pub mut:
	// id               string @[json: 'id']
	content          string @[json: 'content']
	background_color string @[json: 'backgroundColor']
	text_color       string @[json: 'textColor']
	is_closeable     bool   @[json: 'isCloseable']
}
