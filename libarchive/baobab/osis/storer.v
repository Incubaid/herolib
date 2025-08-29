module osis

import freeflowuniverse.herolib.data.ourdb { OurDB }
import os

pub struct Storer {
pub mut:
	db OurDB
}

pub fn new_storer() !Storer {
	return Storer{
		db: ourdb.new()!
	}
}
