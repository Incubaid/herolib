module kubernetes

pub struct KubernetesError {
	Error
pub:
	code      int    // HTTP status code
	reason    string // Kubernetes reason field
	message   string // Descriptive error message
	namespace string
	resource  string
}

pub fn (err KubernetesError) msg() string {
	return '${err.reason} (${err.code}): ${err.message} in ${err.namespace}/${err.resource}'
}

pub fn (err KubernetesError) code() int {
	return err.code
}

pub struct ResourceNotFoundError {
	Error
pub:
	resource_type string
	resource_name string
	namespace     string
}

pub struct ConnectionError {
	Error
pub:
	host    string
	port    int
	details string
}

pub struct ValidationError {
	Error
pub:
	field   string
	message string
}