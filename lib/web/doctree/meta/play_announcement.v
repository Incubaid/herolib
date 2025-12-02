module meta

import incubaid.herolib.core.playbook { PlayBook }

// ============================================================
// ANNOUNCEMENT: Process announcement bar (optional)
// ============================================================
fn play_announcement(mut plbook PlayBook, mut site Site) ! {
	mut announcement_actions := plbook.find(filter: 'site.announcement')!

	if announcement_actions.len > 0 {
		// Only process the first announcement action
		mut action := announcement_actions[0]
		mut p := action.params

		content := p.get('content') or {
			return error('!!site.announcement: must specify "content"')
		}

		site.announcements << Announcement{
			// id:               p.get('id')!
			content:          content
			background_color: p.get_default('background_color', '#20232a')!
			text_color:       p.get_default('text_color', '#fff')!
			is_closeable:     p.get_default_true('is_closeable')
		}

		action.done = true
	}
}
