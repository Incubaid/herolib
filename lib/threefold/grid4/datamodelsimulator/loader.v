module datamodelsimulator

import json
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.threefold.grid4.datamodel { Node }

// load the cloudboxes from a path
pub fn load(path string) ![]Node {
	mut p := pathlib.get_dir(path: path, create: false)!
	mut items := p.list(regex: [r'.*\.json$'])!
	mut r := []Node{}
	for mut item in items.paths {
		d := item.read()!
		mynode := json.decode(Node, d)!
		r << mynode
	}
	return r
}
