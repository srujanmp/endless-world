extends CanvasLayer
class_name LearningJournal
## Modern, translucent book-style journal for accumulated learning.

const FONT_PATH        := "res://assets/fonts/Jersey10-Regular.ttf"
const JOURNAL_LAYER    := 30

const BG_OVERLAY       := Color(0.0, 0.0, 0.0, 0.5)
const BOOK_BG          := Color(0.15, 0.07, 0.02, 0.75)
const COVER_COLOR      := Color(0.2, 0.1, 0.04, 0.85)
const SPINE_COLOR      := Color(0.08, 0.03, 0.01, 0.9)
const CARD_BORDER      := Color(0.72, 0.40, 0.10, 0.5)

const ACCENT_COLOR     := Color(1.0, 0.85, 0.3, 1.0)
const HEADER_COLOR     := Color(1.0, 0.85, 0.3, 1.0)
const BODY_COLOR       := Color(1.0, 0.95, 0.8, 1.0)
const TEXT_SECONDARY   := Color(0.85, 0.75, 0.6, 1.0)

const TAB_ACTIVE       := Color(0.25, 0.12, 0.03, 0.85)
const TAB_INACTIVE     := Color(0.15, 0.07, 0.02, 0.6)
const CARD_BG          := Color(0.25, 0.12, 0.03, 0.5)

const POPUP_W          := 820.0
const POPUP_H          := 560.0
const SPINE_W          := 42.0

const TAB_NAMES := ["Solved Riddles", "Concepts", "Fun Facts"]

var _overlay: ColorRect
var _book_root: Control
var _spine: Panel
var _page_container: Panel
var _tab_buttons: Array = []
var _content_scroll: ScrollContainer
var _content_wrapper: Control
var _content_vbox: VBoxContainer
var _close_btn: Button
var _title_label: Label
var _font: Font
var _current_tab: int = 0

func open() -> void:
	_font = load(FONT_PATH)
	await _build_ui()
	_show_tab(0)
	_animate_open()

func close() -> void:
	_animate_close()

func _build_ui() -> void:
	layer = JOURNAL_LAYER

	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(BG_OVERLAY, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_book_root = Control.new()
	_book_root.custom_minimum_size = Vector2(POPUP_W, POPUP_H)
	_book_root.size = Vector2(POPUP_W, POPUP_H)
	_book_root.pivot_offset = Vector2(POPUP_W * 0.5, POPUP_H * 0.5)
	_book_root.modulate.a = 0.0
	add_child(_book_root)

	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	_book_root.position = Vector2((vp.x - POPUP_W) * 0.5, (vp.y - POPUP_H) * 0.5)

	# Main background
	var book_bg := _make_panel(BOOK_BG, 16)
	book_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_sb = book_bg.get_theme_stylebox("panel") as StyleBoxFlat
	bg_sb.border_width_left = 1
	bg_sb.border_width_top = 1
	bg_sb.border_width_right = 1
	bg_sb.border_width_bottom = 1
	bg_sb.border_color = CARD_BORDER
	bg_sb.shadow_color = Color(0, 0, 0, 0.5)
	bg_sb.shadow_size = 15
	_book_root.add_child(book_bg)

	# Spine
	_spine = _make_panel(SPINE_COLOR, 0)
	_spine.custom_minimum_size = Vector2(SPINE_W, POPUP_H)
	_spine.size = Vector2(SPINE_W, POPUP_H)
	var spine_sb = _spine.get_theme_stylebox("panel") as StyleBoxFlat
	spine_sb.corner_radius_top_left = 16
	spine_sb.corner_radius_bottom_left = 16
	_book_root.add_child(_spine)

	for i in range(6):
		var ln := ColorRect.new()
		ln.color = ACCENT_COLOR.darkened(0.3)
		ln.size = Vector2(SPINE_W - 8, 2)
		ln.position = Vector2(4, 50 + i * 80)
		_spine.add_child(ln)

	var spine_lbl := Label.new()
	spine_lbl.text = "JOURNAL"
	spine_lbl.add_theme_font_override("font", _font)
	spine_lbl.add_theme_font_size_override("font_size", 22)
	spine_lbl.add_theme_color_override("font_color", ACCENT_COLOR)
	spine_lbl.rotation_degrees = -90
	spine_lbl.position = Vector2(SPINE_W - 6, POPUP_H * 0.5 + 50)
	_spine.add_child(spine_lbl)

	# Cover strip
	var cover_strip := _make_panel(COVER_COLOR, 0)
	cover_strip.custom_minimum_size = Vector2(POPUP_W - SPINE_W, 55)
	cover_strip.size = Vector2(POPUP_W - SPINE_W, 55)
	cover_strip.position = Vector2(SPINE_W, 0)
	var cs_sb = cover_strip.get_theme_stylebox("panel") as StyleBoxFlat
	cs_sb.corner_radius_top_right = 16
	cs_sb.border_width_bottom = 1
	cs_sb.border_color = CARD_BORDER
	_book_root.add_child(cover_strip)

	# Title & Icon
	var title_hbox := HBoxContainer.new()
	title_hbox.position = Vector2(16, 12)
	title_hbox.add_theme_constant_override("separation", 10)
	cover_strip.add_child(title_hbox)
	
	var book_icon := _create_svg_icon("book", 26, ACCENT_COLOR)
	title_hbox.add_child(book_icon)

	_title_label = Label.new()
	_title_label.text = "Learning Journal  —  " + Global.selected_topic.capitalize()
	_title_label.add_theme_font_override("font", _font)
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", ACCENT_COLOR)
	title_hbox.add_child(_title_label)

	# Close button
	_close_btn = Button.new()
	_close_btn.custom_minimum_size = Vector2(40, 40)
	_close_btn.position = Vector2(POPUP_W - SPINE_W - 50, 8)
	_close_btn.focus_mode = Control.FOCUS_NONE
	_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var close_icon = _create_svg_icon("close", 20, ACCENT_COLOR)
	close_icon.position = Vector2(10, 10)
	close_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_close_btn.add_child(close_icon)
	
	var cb_hover = StyleBoxFlat.new()
	cb_hover.bg_color = Color(1, 1, 1, 0.1)
	cb_hover.corner_radius_top_left = 6
	cb_hover.corner_radius_top_right = 6
	cb_hover.corner_radius_bottom_left = 6
	cb_hover.corner_radius_bottom_right = 6
	_close_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_close_btn.add_theme_stylebox_override("hover", cb_hover)
	_close_btn.add_theme_stylebox_override("pressed", cb_hover)
	_close_btn.pressed.connect(close)
	cover_strip.add_child(_close_btn)

	# Tabs
	var tab_y := 55.0
	var tab_w := (POPUP_W - SPINE_W) / TAB_NAMES.size()
	_tab_buttons.clear()
	for i in range(TAB_NAMES.size()):
		var tb := Button.new()
		tb.text = TAB_NAMES[i]
		tb.add_theme_font_override("font", _font)
		tb.add_theme_font_size_override("font_size", 20)
		tb.add_theme_color_override("font_color", BODY_COLOR)
		tb.add_theme_stylebox_override("normal", _make_stylebox(TAB_INACTIVE, 0))
		tb.add_theme_stylebox_override("hover", _make_stylebox(TAB_ACTIVE.lightened(0.1), 0))
		tb.add_theme_stylebox_override("pressed", _make_stylebox(TAB_ACTIVE, 0))
		tb.focus_mode = Control.FOCUS_NONE
		tb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tb.custom_minimum_size = Vector2(tab_w, 40)
		tb.size = Vector2(tab_w, 40)
		tb.position = Vector2(SPINE_W + i * tab_w, tab_y)
		var idx := i
		tb.pressed.connect(func(): _show_tab(idx))
		_book_root.add_child(tb)
		_tab_buttons.append(tb)

	# Page area
	var page_y := tab_y + 40.0
	_page_container = _make_panel(Color(0,0,0,0), 0)
	_page_container.custom_minimum_size = Vector2(POPUP_W - SPINE_W, POPUP_H - page_y)
	_page_container.size = Vector2(POPUP_W - SPINE_W, POPUP_H - page_y)
	_page_container.position = Vector2(SPINE_W, page_y)
	_page_container.clip_contents = true
	var p_sb = _page_container.get_theme_stylebox("panel") as StyleBoxFlat
	p_sb.border_width_top = 1
	p_sb.border_color = CARD_BORDER
	_book_root.add_child(_page_container)

	_content_scroll = ScrollContainer.new()
	_content_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_scroll.offset_left = 16
	_content_scroll.offset_top = 16
	_content_scroll.offset_right = -16
	_content_scroll.offset_bottom = -16
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page_container.add_child(_content_scroll)

	_content_wrapper = Control.new()
	_content_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_wrapper)
	
	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 12)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_content_wrapper.add_child(_content_vbox)

func _show_tab(idx: int) -> void:
	_current_tab = idx

	for i in range(_tab_buttons.size()):
		var tb: Button = _tab_buttons[i]
		if i == idx:
			tb.add_theme_stylebox_override("normal", _make_stylebox(TAB_ACTIVE, 0))
			tb.add_theme_color_override("font_color", ACCENT_COLOR)
		else:
			tb.add_theme_stylebox_override("normal", _make_stylebox(TAB_INACTIVE, 0))
			tb.add_theme_color_override("font_color", TEXT_SECONDARY)

	if _content_vbox.get_child_count() > 0:
		var out_tw := create_tween()
		out_tw.tween_property(_content_vbox, "modulate:a", 0.0, 0.15).set_ease(Tween.EASE_OUT)
		out_tw.tween_callback(func(): _load_tab_content(idx))
	else:
		_load_tab_content(idx)

func _load_tab_content(idx: int) -> void:
	for child in _content_vbox.get_children():
		child.free()
	
	_content_wrapper.custom_minimum_size.y = 0 # reset scroll
	
	match idx:
		0: _populate_riddles()
		1: _populate_concepts()
		2: _populate_facts()

	await get_tree().process_frame
	_content_wrapper.custom_minimum_size.y = _content_vbox.size.y

	_content_vbox.modulate.a = 0.0
	_content_vbox.position.y = 20
	var in_tw := create_tween().set_parallel(true)
	in_tw.tween_property(_content_vbox, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	in_tw.tween_property(_content_vbox, "position:y", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _populate_riddles() -> void:
	var riddles: Array = Global.learning_journal.get("solved_riddles", []).duplicate()
	riddles.reverse()
	if riddles.is_empty():
		_add_empty_message("No solved riddles yet.\nGo answer some questions to fill this page!")
		return
	for entry in riddles:
		var q: String = entry.get("question", "?")
		var a: String = entry.get("answer", "?")
		var t: String = entry.get("topic", "").capitalize()
		_add_entry("check", q, "Answer: " + a.capitalize() + ("   [" + t + "]" if not t.is_empty() else ""))

func _populate_concepts() -> void:
	var concepts: Array = Global.learning_journal.get("concepts", []).duplicate()
	concepts.reverse()
	if concepts.is_empty():
		_add_empty_message("No concepts learned yet.\nConcepts are captured automatically when\nquestions load. Play a round to fill this page!")
		return
	for entry in concepts:
		var name_str: String = entry.get("name", "")
		var def_str: String  = entry.get("definition", name_str)
		var topic: String    = entry.get("topic", "").capitalize()
		_add_entry("lightbulb", name_str + ("   [" + topic + "]" if not topic.is_empty() else ""), def_str)

func _populate_facts() -> void:
	var facts: Array = Global.learning_journal.get("fun_facts", []).duplicate()
	facts.reverse()
	if facts.is_empty():
		_add_empty_message("No fun facts collected yet.\nThe AI companion shares a fact every 2 minutes\nduring gameplay. Keep playing!")
		return
	for entry in facts:
		var text: String  = entry.get("text", "")
		var topic: String = entry.get("topic", "").capitalize()
		_add_entry("sparkle", "Fun Fact" + ("   [" + topic + "]" if not topic.is_empty() else ""), text)

func _add_entry(icon: String, heading: String, body: String) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = CARD_BG
	card_sb.border_width_left = 1
	card_sb.border_width_top = 1
	card_sb.border_width_right = 1
	card_sb.border_width_bottom = 1
	card_sb.border_color = CARD_BORDER
	card_sb.corner_radius_top_left = 10
	card_sb.corner_radius_top_right = 10
	card_sb.corner_radius_bottom_left = 10
	card_sb.corner_radius_bottom_right = 10
	card_sb.content_margin_left = 16
	card_sb.content_margin_top = 12
	card_sb.content_margin_right = 16
	card_sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_sb)
	_content_vbox.add_child(card)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)
	
	var icn := _create_svg_icon(icon, 24, ACCENT_COLOR)
	hbox.add_child(icn)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vb)

	var h_lbl := Label.new()
	h_lbl.text = heading
	h_lbl.add_theme_font_override("font", _font)
	h_lbl.add_theme_font_size_override("font_size", 22)
	h_lbl.add_theme_color_override("font_color", HEADER_COLOR)
	h_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(h_lbl)

	if body != "" and body != heading:
		var b_lbl := Label.new()
		b_lbl.text = body
		b_lbl.add_theme_font_override("font", _font)
		b_lbl.add_theme_font_size_override("font_size", 18)
		b_lbl.add_theme_color_override("font_color", BODY_COLOR)
		b_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_child(b_lbl)

func _add_empty_message(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", TEXT_SECONDARY)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.modulate.a = 0.6
	_content_vbox.add_child(lbl)

func _animate_open() -> void:
	_book_root.scale = Vector2(0.85, 0.85)
	_book_root.position.y += 30
	_book_root.modulate.a = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_book_root, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tw.tween_property(_book_root, "position:y", _book_root.position.y - 30, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tw.tween_property(_book_root, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	tw.tween_property(_overlay, "color:a", BG_OVERLAY.a, 0.4)

func _animate_close() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_book_root, "scale", Vector2(0.95, 0.95), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	tw.tween_property(_book_root, "position:y", _book_root.position.y + 15, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	tw.tween_property(_book_root, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_property(_overlay, "color:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)

func _make_panel(bg: Color, corner: int) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = corner
	sb.corner_radius_top_right = corner
	sb.corner_radius_bottom_left = corner
	sb.corner_radius_bottom_right = corner
	p.add_theme_stylebox_override("panel", sb)
	return p

func _make_stylebox(bg: Color, corner: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = corner
	sb.corner_radius_top_right = corner
	sb.corner_radius_bottom_left = corner
	sb.corner_radius_bottom_right = corner
	return sb

func _create_svg_icon(icon_name: String, icon_size: int, color: Color) -> Control:
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
		"book":
			control.draw_rect(Rect2(s*0.1, s*0.2, s*0.35, s*0.6), Color(0,0,0,0), false, 2.0)
			control.draw_rect(Rect2(s*0.5, s*0.2, s*0.35, s*0.6), Color(0,0,0,0), false, 2.0)
			control.draw_line(Vector2(cx, s*0.15), Vector2(cx, s*0.8), color, 2.0, true)
			control.draw_line(Vector2(s*0.1, s*0.2), Vector2(cx, s*0.2), color, 2.0, true)
			control.draw_line(Vector2(s*0.1, s*0.8), Vector2(cx, s*0.8), color, 2.0, true)
			control.draw_line(Vector2(s*0.1, s*0.2), Vector2(s*0.1, s*0.8), color, 2.0, true)
			control.draw_line(Vector2(s*0.9, s*0.2), Vector2(cx, s*0.2), color, 2.0, true)
			control.draw_line(Vector2(s*0.9, s*0.8), Vector2(cx, s*0.8), color, 2.0, true)
			control.draw_line(Vector2(s*0.9, s*0.2), Vector2(s*0.9, s*0.8), color, 2.0, true)
		"check":
			control.draw_line(Vector2(s*0.2, cy), Vector2(s*0.4, s*0.7), color, 2.5, true)
			control.draw_line(Vector2(s*0.4, s*0.7), Vector2(s*0.8, s*0.3), color, 2.5, true)
		"lightbulb":
			control.draw_arc(Vector2(cx, s * 0.35), s * 0.25, deg_to_rad(-40), deg_to_rad(220), 16, color, 2.0, true)
			control.draw_line(Vector2(s * 0.38, s * 0.58), Vector2(s * 0.38, s * 0.75), color, 2.0, true)
			control.draw_line(Vector2(s * 0.62, s * 0.58), Vector2(s * 0.62, s * 0.75), color, 2.0, true)
			control.draw_line(Vector2(s * 0.38, s * 0.75), Vector2(s * 0.62, s * 0.75), color, 2.0, true)
		"sparkle":
			control.draw_line(Vector2(cx, s*0.1), Vector2(cx, s*0.9), color, 2.0, true)
			control.draw_line(Vector2(s*0.1, cy), Vector2(s*0.9, cy), color, 2.0, true)
			control.draw_line(Vector2(s*0.25, s*0.25), Vector2(s*0.75, s*0.75), color, 2.0, true)
			control.draw_line(Vector2(s*0.25, s*0.75), Vector2(s*0.75, s*0.25), color, 2.0, true)
		"close":
			var m := s * 0.2
			control.draw_line(Vector2(m, m), Vector2(s - m, s - m), color, 2.0, true)
			control.draw_line(Vector2(s - m, m), Vector2(m, s - m), color, 2.0, true)
