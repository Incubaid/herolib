module meta

// is to import one site into another, can be used to e.g. import static parts from one location into the build one we are building
pub struct ImportItem {
pub mut:
	url     string // http git url can be to specific path
	path    string
	dest    string            // location in the docs folder of the place where we will build the documentation site e.g. docusaurus
	replace map[string]string // will replace ${NAME} in the imported content
	visible bool = true
}
