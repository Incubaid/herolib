module dbfs

import incubaid.herolib.core.smartid

// get u32 from sid as string
pub fn sid2int(sid string) u32 {
	return smartid.sid_int(sid)
}

// represent sid as string, from u32
fn int2sid(sid u32) string {
	return smartid.sid_str(sid)
}
