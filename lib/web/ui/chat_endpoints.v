module ui

import os

pub fn render_chat_alt(app &App) !string {
	tpl := os.join_path(os.dir(@FILE), 'templates', 'chat.html')
	content := os.read_file(tpl)!
	menu_content := menu_html(app.menu, 0, 'm')
	mut result := content
	result = result.replace('{{.title}}', app.title)
	result = result.replace('{{.menu_html}}', menu_content)
	result = result.replace('{{.css_colors_url}}', '/static/css/colors.css')
	result = result.replace('{{.css_main_url}}', '/static/css/main.css')
	result = result.replace('{{.css_chat_url}}', '/static/css/chat.css')
	result = result.replace('{{.js_theme_url}}', '/static/js/theme.js')
	result = result.replace('{{.js_chat_url}}', '/static/js/chat.js')
	// version banner
	result = result.replace('</body>', '<div class="v-badge">Rendered by: chat</div></body>')
	return result
}
