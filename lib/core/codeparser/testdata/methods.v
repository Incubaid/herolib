module testdata

import time

// activate sets the user as active
pub fn (mut u User) activate() {
	u.active = true
	u.updated = time.now().str()
}

// deactivate sets the user as inactive
pub fn (mut u User) deactivate() {
	u.active = false
	u.updated = time.now().str()
}

// is_active returns whether the user is active
pub fn (u User) is_active() bool {
	return u.active
}

// get_display_name returns the display name for the user
pub fn (u &User) get_display_name() string {
	if u.username != '' {
		return u.username
	}
	return u.email
}

// set_profile updates the user profile
pub fn (mut u User) set_profile(mut profile Profile) ! {
	if profile.user_id != u.id {
		return error('profile does not belong to this user')
	}
}

// get_profile_info returns profile information as string
pub fn (p &Profile) get_profile_info() string {
	return 'Bio: ${p.bio}, Followers: ${p.followers}'
}
