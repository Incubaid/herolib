module ui

// Default menu for the Admin UI. Used when no custom menu is provided.
pub fn get_default_menu() []MenuItem {
	return [
		MenuItem{
			title: 'Dashboard'
			href:  '/admin'
		},
		MenuItem{
			title: 'HeroScript'
			href:  '/admin/heroscript'
		},
		MenuItem{
			title: 'Chat'
			href:  '/admin/chat'
		},
		MenuItem{
			title: 'Heroprompt'
			href:  '/admin/heroprompt'
		},
		MenuItem{
			title:    'Users'
			children: [
				MenuItem{
					title: 'Overview'
					href:  '/admin/users/overview'
				},
				MenuItem{
					title: 'Create'
					href:  '/admin/users/create'
				},
				MenuItem{
					title: 'Roles'
					href:  '/admin/users/roles'
				},
			]
		},
		MenuItem{
			title:    'Content'
			children: [
				MenuItem{
					title: 'Pages'
					href:  '/admin/content/pages'
				},
				MenuItem{
					title: 'Media'
					href:  '/admin/content/media'
				},
				MenuItem{
					title:    'Settings'
					children: [
						MenuItem{
							title: 'SEO'
							href:  '/admin/content/settings/seo'
						},
						MenuItem{
							title: 'Themes'
							href:  '/admin/content/settings/themes'
						},
					]
				},
			]
		},
		MenuItem{
			title:    'System'
			children: [
				MenuItem{
					title: 'Status'
					href:  '/admin/system/status'
				},
				MenuItem{
					title: 'Logs'
					href:  '/admin/system/logs'
				},
				MenuItem{
					title: 'Backups'
					href:  '/admin/system/backups'
				},
			]
		},
	]
}
