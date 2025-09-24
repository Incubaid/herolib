module ui

import os

// Render the Heroprompt admin page using feature template
pub fn render_heroprompt_page(app &App) !string {
	tpl := os.join_path(os.dir(@FILE), 'templates', 'heroprompt.html')
	content := os.read_file(tpl)!
	menu_content := menu_html(app.menu, 0, 'm')
	mut result := content
	result = result.replace('{{.title}}', app.title)
	result = result.replace('{{.menu_html}}', menu_content)
	result = result.replace('{{.css_colors_url}}', '/static/css/colors.css')
	result = result.replace('{{.css_main_url}}', '/static/css/main.css')
	result = result.replace('{{.css_heroprompt_url}}', '/static/css/heroprompt.css')
	result = result.replace('{{.js_theme_url}}', '/static/js/theme.js')
	result = result.replace('{{.js_heroprompt_url}}', '/static/js/heroprompt.js')
	// version banner
	result = result.replace('</body>', '<div class="v-badge">Rendered by: heroprompt</div></body>')
	return result
}
