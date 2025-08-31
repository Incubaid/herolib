module osis

pub fn new(config OSISConfig) !OSIS {
	return OSIS{
		indexer: new_indexer()!
		storer:  new_storer()!
	}
}
