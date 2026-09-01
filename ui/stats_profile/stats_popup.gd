extends Panel
## Modern stats overlay with glassmorphic card UI and SVG-drawn icons.
## Entirely code-driven — no .tscn dependency.

signal closed
signal stats_reset

const CARD_COLOR := Color(0.15, 0.07, 0.02, 0.75)
const CARD_BORDER := Color(0.72, 0.40, 0.10, 0.7)
const ACCENT := Color(1.0, 0.85, 0.3, 1.0)
const ACCENT_WARM := Color(1.0, 0.6, 0.1, 1.0)
const TEXT_PRIMARY := Color(1.0, 0.95, 0.8, 1.0)
const TEXT_SECONDARY := Color(0.85, 0.75, 0.6, 1.0)
const BG_OVERLAY := Color(0.0, 0.0, 0.0, 0.5)
const DANGER := Color(0.9, 0.3, 0.3, 1.0)
const SUCCESS := Color(0.4, 0.9, 0.4, 1.0)

var _font: Font
var _scroll: ScrollContainer
var _grid: GridContainer


func _ready() -> void:
	_font = load("res://assets/fonts/Jersey10-Regular.ttf")
	_build_ui()
	refresh()


func _build_ui() -> void:
	# Full-screen overlay
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = BG_OVERLAY
	add_theme_stylebox_override("panel", bg_style)

	# Center card container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(680, 540)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = CARD_COLOR
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = CARD_BORDER
	card_style.shadow_color = Color(0, 0, 0, 0.4)
	card_style.shadow_size = 12
	card_style.content_margin_left = 28
	card_style.content_margin_right = 28
	card_style.content_margin_top = 24
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)

	# --- Header row ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var icon_panel := _create_svg_icon("chart")
	header.add_child(icon_panel)

	var title := Label.new()
	title.text = "Player Statistics"
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", TEXT_PRIMARY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := _create_icon_button("close")
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	# --- Separator ---
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = CARD_BORDER
	sep_style.content_margin_top = 0
	sep_style.content_margin_bottom = 0
	sep.add_theme_stylebox_override("separator", sep_style)
	sep.add_theme_constant_override("separation", 1)
	vbox.add_child(sep)

	# --- Scrollable stat grid ---
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_grid)

	# --- Bottom actions ---
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	actions.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(actions)

	var reset_btn := _create_text_button("Reset All", DANGER)
	reset_btn.pressed.connect(_on_reset)
	actions.add_child(reset_btn)

	var done_btn := _create_text_button("Done", ACCENT)
	done_btn.pressed.connect(_on_close)
	actions.add_child(done_btn)


func refresh() -> void:
	# Clear previous cards
	for c in _grid.get_children():
		c.queue_free()

	var s = Global.stats

	var win_rate := 0.0
	if s.total_games > 0:
		win_rate = float(s.total_wins) / float(s.total_games) * 100.0

	var time_min := int(s.total_play_time) / 60
	var time_sec := int(s.total_play_time) % 60

	_add_stat_card("gamepad", "Games", str(s.total_games), ACCENT)
	_add_stat_card("trophy", "Wins", str(s.total_wins), SUCCESS)
	_add_stat_card("x_circle", "Losses", str(s.total_losses), DANGER)
	_add_stat_card("percent", "Win Rate", "%.0f%%" % win_rate, ACCENT_WARM)
	_add_stat_card("clock", "Play Time", "%dm %ds" % [time_min, time_sec], TEXT_SECONDARY)
	_add_stat_card("lightbulb", "Hints Used", str(s.total_hints_used), ACCENT)
	_add_stat_card("star", "Total Score", str(s.total_score), ACCENT_WARM)
	_add_stat_card("mountain", "Best Level", str(s.best_level), SUCCESS)
	_add_stat_card("compass", "Difficulty", Global.difficulty, ACCENT)


func _add_stat_card(icon_name: String, label_text: String, value_text: String, accent: Color) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 90)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.12, 0.03, 0.65)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.25)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var svg_icon := _create_svg_icon(icon_name, 22, accent)
	hbox.add_child(svg_icon)

	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", TEXT_SECONDARY)
	text_vbox.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.add_theme_font_override("font", _font)
	val.add_theme_font_size_override("font_size", 30)
	val.add_theme_color_override("font_color", accent)
	text_vbox.add_child(val)

	_grid.add_child(card)


# ─── SVG Icon Drawing ─────────────────────────────────────────

func _create_svg_icon(icon_name: String, icon_size: int = 28, color: Color = ACCENT) -> Control:
	var container := Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.custom_minimum_size = Vector2(icon_size, icon_size)
	container.set_meta("icon_name", icon_name)
	container.set_meta("icon_color", color)
	container.set_meta("icon_size", icon_size)
	container.draw.connect(_draw_svg_icon.bind(container))
	return container


func _draw_svg_icon(control: Control) -> void:
	var icon_name: String = control.get_meta("icon_name")
	var color: Color = control.get_meta("icon_color")
	var s: float = control.get_meta("icon_size")
	var cx := s * 0.5
	var cy := s * 0.5

	match icon_name:
		"chart":
			# Bar chart icon
			var bar_w := s * 0.18
			control.draw_rect(Rect2(s * 0.1, s * 0.55, bar_w, s * 0.35), color)
			control.draw_rect(Rect2(s * 0.35, s * 0.3, bar_w, s * 0.6), color)
			control.draw_rect(Rect2(s * 0.6, s * 0.1, bar_w, s * 0.8), color)

		"close":
			# X icon
			var m := s * 0.2
			control.draw_line(Vector2(m, m), Vector2(s - m, s - m), color, 2.0, true)
			control.draw_line(Vector2(s - m, m), Vector2(m, s - m), color, 2.0, true)

		"gamepad":
			# Simplified gamepad
			var pts: PackedVector2Array = [
				Vector2(s * 0.15, s * 0.35), Vector2(s * 0.85, s * 0.35),
				Vector2(s * 0.85, s * 0.65), Vector2(s * 0.7, s * 0.75),
				Vector2(s * 0.3, s * 0.75), Vector2(s * 0.15, s * 0.65),
			]
			control.draw_polyline(pts, color, 2.0, true)
			control.draw_circle(Vector2(s * 0.35, s * 0.52), s * 0.06, color)
			control.draw_circle(Vector2(s * 0.65, s * 0.52), s * 0.06, color)

		"trophy":
			# Trophy cup
			control.draw_line(Vector2(s * 0.25, s * 0.2), Vector2(s * 0.75, s * 0.2), color, 2.0, true)
			control.draw_line(Vector2(s * 0.3, s * 0.2), Vector2(s * 0.35, s * 0.55), color, 2.0, true)
			control.draw_line(Vector2(s * 0.7, s * 0.2), Vector2(s * 0.65, s * 0.55), color, 2.0, true)
			control.draw_line(Vector2(s * 0.35, s * 0.55), Vector2(s * 0.65, s * 0.55), color, 2.0, true)
			control.draw_line(Vector2(cx, s * 0.55), Vector2(cx, s * 0.7), color, 2.0, true)
			control.draw_line(Vector2(s * 0.3, s * 0.75), Vector2(s * 0.7, s * 0.75), color, 2.0, true)

		"x_circle":
			# Circle with X
			control.draw_arc(Vector2(cx, cy), s * 0.38, 0, TAU, 24, color, 2.0, true)
			var m := s * 0.28
			control.draw_line(Vector2(m, m), Vector2(s - m, s - m), color, 2.0, true)
			control.draw_line(Vector2(s - m, m), Vector2(m, s - m), color, 2.0, true)

		"percent":
			# % sign
			control.draw_circle(Vector2(s * 0.3, s * 0.3), s * 0.1, color)
			control.draw_circle(Vector2(s * 0.7, s * 0.7), s * 0.1, color)
			control.draw_line(Vector2(s * 0.75, s * 0.2), Vector2(s * 0.25, s * 0.8), color, 2.0, true)

		"clock":
			# Clock face
			control.draw_arc(Vector2(cx, cy), s * 0.38, 0, TAU, 24, color, 2.0, true)
			control.draw_line(Vector2(cx, cy), Vector2(cx, s * 0.2), color, 2.0, true)
			control.draw_line(Vector2(cx, cy), Vector2(s * 0.68, cy), color, 2.0, true)

		"lightbulb":
			# Light bulb
			control.draw_arc(Vector2(cx, s * 0.35), s * 0.25, deg_to_rad(-40), deg_to_rad(220), 16, color, 2.0, true)
			control.draw_line(Vector2(s * 0.38, s * 0.58), Vector2(s * 0.38, s * 0.75), color, 2.0, true)
			control.draw_line(Vector2(s * 0.62, s * 0.58), Vector2(s * 0.62, s * 0.75), color, 2.0, true)
			control.draw_line(Vector2(s * 0.38, s * 0.75), Vector2(s * 0.62, s * 0.75), color, 2.0, true)

		"star":
			# 5-point star
			var points: PackedVector2Array = []
			for i in 5:
				var angle := deg_to_rad(-90 + i * 72)
				points.append(Vector2(cx + cos(angle) * s * 0.4, cy + sin(angle) * s * 0.4))
				var inner_angle := deg_to_rad(-90 + i * 72 + 36)
				points.append(Vector2(cx + cos(inner_angle) * s * 0.18, cy + sin(inner_angle) * s * 0.18))
			points.append(points[0])
			control.draw_polyline(points, color, 2.0, true)

		"mountain":
			# Mountain peak
			control.draw_line(Vector2(s * 0.1, s * 0.8), Vector2(s * 0.4, s * 0.2), color, 2.0, true)
			control.draw_line(Vector2(s * 0.4, s * 0.2), Vector2(s * 0.55, s * 0.45), color, 2.0, true)
			control.draw_line(Vector2(s * 0.55, s * 0.45), Vector2(s * 0.65, s * 0.35), color, 2.0, true)
			control.draw_line(Vector2(s * 0.65, s * 0.35), Vector2(s * 0.9, s * 0.8), color, 2.0, true)
			control.draw_line(Vector2(s * 0.1, s * 0.8), Vector2(s * 0.9, s * 0.8), color, 2.0, true)

		"compass":
			# Compass
			control.draw_arc(Vector2(cx, cy), s * 0.38, 0, TAU, 24, color, 2.0, true)
			control.draw_line(Vector2(cx, s * 0.15), Vector2(cx + s * 0.08, cy), color, 2.0, true)
			control.draw_line(Vector2(cx, s * 0.15), Vector2(cx - s * 0.08, cy), color, 2.0, true)
			control.draw_line(Vector2(cx, s * 0.85), Vector2(cx + s * 0.08, cy), color, 2.0, true)
			control.draw_line(Vector2(cx, s * 0.85), Vector2(cx - s * 0.08, cy), color, 2.0, true)


# ─── Button helpers ────────────────────────────────────────────

func _create_icon_button(icon_name: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(36, 36)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(1.0, 1.0, 1.0, 0.1)
	sb_hover.corner_radius_top_left = 6
	sb_hover.corner_radius_top_right = 6
	sb_hover.corner_radius_bottom_left = 6
	sb_hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	
	btn.tooltip_text = "Close"

	var icon_ctrl := _create_svg_icon(icon_name, 20, TEXT_SECONDARY)
	icon_ctrl.position = Vector2(8, 8)
	btn.add_child(icon_ctrl)

	return btn


func _create_text_button(text: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 40)
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", accent)
	btn.add_theme_color_override("font_pressed_color", accent.darkened(0.2))
	btn.focus_mode = Control.FOCUS_NONE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.15)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.4)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(accent.r, accent.g, accent.b, 0.3)
	sb_hover.corner_radius_top_left = 8
	sb_hover.corner_radius_top_right = 8
	sb_hover.corner_radius_bottom_left = 8
	sb_hover.corner_radius_bottom_right = 8
	sb_hover.border_width_left = 1
	sb_hover.border_width_top = 1
	sb_hover.border_width_right = 1
	sb_hover.border_width_bottom = 1
	sb_hover.border_color = accent
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)

	return btn


# ─── Callbacks ─────────────────────────────────────────────────

func _on_close() -> void:
	closed.emit()
	visible = false


func _on_reset() -> void:
	stats_reset.emit()
