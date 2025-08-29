module osis

pub struct OSIS {
pub mut:
	indexer Indexer // storing indeces
	storer  Storer
}

@[params]
pub struct OSISConfig {
pub:
	directory string
	name      string
	secret    string
	reset     bool
}
