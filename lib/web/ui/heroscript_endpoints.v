module ui

import os

// Render HeroScript page
pub fn render_heroscript_alt(app &App) !string {
	tpl := os.join_path(os.dir(@FILE), 'templates', 'heroscript_editor.html')
	content := os.read_file(tpl)!
	menu_content := menu_html(app.menu, 0, 'm')
	mut result := content
	result = result.replace('{{.title}}', app.title)
	result = result.replace('{{.menu_html}}', menu_content)
	// shared CSS/JS
	result = result.replace('{{.css_colors_url}}', '/static/css/colors.css')
	result = result.replace('{{.css_main_url}}', '/static/css/main.css')
	result = result.replace('{{.js_theme_url}}', '/static/js/theme.js')
	// feature CSS/JS
	result = result.replace('{{.css_heroscript_url}}', '/static/css/heroscript.css')
	result = result.replace('{{.js_heroscript_url}}', '/static/js/heroscript.js')
	// version banner
	result = result.replace('</body>', '<div class="v-badge">Rendered by: heroscript</div></body>')
	return result
}
