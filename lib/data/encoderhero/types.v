module encoderhero

// Encodable is an interface for custom heroscript encoding
pub interface Encodable {
	heroscript() string
}

// Constants for internal use
const null_in_bytes = 'null'
const true_in_string = 'true'
const false_in_string = 'false'