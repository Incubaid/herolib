module podman

// PodmanError represents errors that occur during podman operations
pub struct PodmanError {
	Error
pub:
	code    int    // Error code from podman command
	message string // Error message
}

// msg returns the error message
pub fn (err PodmanError) msg() string {
	return err.message
}

// code returns the error code
pub fn (err PodmanError) code() int {
	return err.code
}

// ContainerError represents container-specific errors
pub struct ContainerError {
	Error
pub:
	operation string
	container string
	exit_code int
	message   string
	stderr    string
}

pub fn (err ContainerError) msg() string {
	return 'Container operation failed: ${err.operation}\nContainer: ${err.container}\nMessage: ${err.message}\nStderr: ${err.stderr}'
}

pub fn (err ContainerError) code() int {
	return err.exit_code
}

// ImageError represents image-specific errors
pub struct ImageError {
	Error
pub:
	operation string
	image     string
	exit_code int
	message   string
	stderr    string
}

pub fn (err ImageError) msg() string {
	return 'Image operation failed: ${err.operation}\nImage: ${err.image}\nMessage: ${err.message}\nStderr: ${err.stderr}'
}

pub fn (err ImageError) code() int {
	return err.exit_code
}

// Helper functions to create specific errors

// new_podman_error creates a new podman error
pub fn new_podman_error(operation string, resource string, exit_code int, message string) PodmanError {
	return PodmanError{
		code:    exit_code
		message: 'Podman ${operation} failed for ${resource}: ${message}'
	}
}

// new_container_error creates a new container error
pub fn new_container_error(operation string, container string, exit_code int, message string, stderr string) ContainerError {
	return ContainerError{
		operation: operation
		container: container
		exit_code: exit_code
		message:   message
		stderr:    stderr
	}
}

// new_image_error creates a new image error
pub fn new_image_error(operation string, image string, exit_code int, message string, stderr string) ImageError {
	return ImageError{
		operation: operation
		image:     image
		exit_code: exit_code
		message:   message
		stderr:    stderr
	}
}
