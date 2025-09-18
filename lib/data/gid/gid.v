module gid

import freeflowuniverse.herolib.core.texttools

pub struct GID {
pub mut:
	circle string // unique dns name for the circle
	cid    u32    // unique id inside the circle
}

// txt is optional and is ...:..  first ... is circle dns name which is name_fixed strings and . last is id in string format
pub fn new(txt_ string) !GID {
	txt := txt_.trim_space()
	if txt == '' {
		return GID{}
	}

	if !txt.contains(':') {
		return error('Invalid GID format, should be circle:id')
	}

	parts := txt.split(':')
	if parts.len != 2 {
		return error('Invalid GID format, should be circle:id')
	}

	circle := texttools.name_fix(parts[0])
	if circle == '' {
		return error('Circle name cannot be empty')
	}

	cid_str := parts[1].trim_space()
	cid := cid_str.u32() // TODO: what if this is no nr?

	return GID{
		circle: circle
		cid:    cid
	}
}

pub fn new_from_parts(circle_ string, cid u32) !GID {
	mut circle := circle_
	if circle.trim_space() == '' {
		circle = 'default'
	}

	return GID{
		circle: circle
		cid:    cid
	}
}

// returns a string representation in "circle:id" format
pub fn (gid GID) str() string {
	return '${gid.circle}:${gid.cid}'
}

// Check if the GID is empty (either circle is empty or cid is 0)
pub fn (gid GID) empty() bool {
	return gid.circle == '' || gid.cid == 0
}

// Compare two GIDs for equality
pub fn (gid GID) equals(other GID) bool {
	return gid.circle == other.circle && gid.cid == other.cid
}
