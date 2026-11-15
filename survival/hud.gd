extends Control
class_name SurvivalHud

# Survival's status display, drawn by hand so it stays compact and readable:
#   top edge    XP strip (fills up to the next level-up perk)
#   top left    round + event, wave progress, coins / kills, weapon slots,
#               dash cooldown, active buffs, score and threat
#   top right   combo counter (under the hearts)

const FONT := preload("res://assets/fonts/Jersey10-Regular.ttf")
const PAD := 12.0
const W := 292.0                # panel width
const H := 182.0                # panel height (the radar sits right below)

var game: Node                  # SurvivalGame
var _bg := StyleBoxFlat.new()
var _slot := StyleBoxFlat.new()
var _slot_on := StyleBoxFlat.new()
var _tex := {}
var _combo_pop := 0.0
var _last_combo := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg.bg_color = Color(0.04, 0.06, 0.13, 0.78)
	_bg.set_corner_radius_all(6)
	_bg.set_border_width_all(2)
	_bg.border_color = Color(1.0, 0.8, 0.28, 0.55)
	for sb in [_slot, _slot_on]:
		sb.bg_color = Color(0.1, 0.13, 0.24, 0.9)
		sb.set_corner_radius_all(4)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.3, 0.36, 0.52)
	_slot_on.bg_color = Color(0.2, 0.24, 0.42, 0.95)
	_slot_on.border_color = PixelUI.GOLD


func _process(delta: float) -> void:
	_combo_pop = maxf(0.0, _combo_pop - delta)
	var c: int = game.combo
	if c > _last_combo:
		_combo_pop = 0.15
	_last_combo = c
	queue_redraw()


func icon(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load("res://assets/survival/%s.png" % name)
	return _tex[name]


# Outlined text with its top-left corner at `p`; returns the text's width.
func _text(p: Vector2, s: String, sz: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> float:
	var at := p + Vector2(0, FONT.get_ascent(sz))
	draw_string_outline(FONT, at, s, align, width, sz, 4, Color(0, 0, 0, 0.85))
	draw_string(FONT, at, s, align, width, sz, col)
	return FONT.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x


func _bar(r: Rect2, frac: float, col: Color) -> void:
	draw_rect(r.grow(1.0), Color(0, 0, 0, 0.85))
	draw_rect(r, Color(0.1, 0.12, 0.22))
	if frac > 0.0:
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), col)
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), 2.0)), col.lightened(0.45))


func _draw() -> void:
	var st: String = game.state
	if st == "intro":
		return
	# ---- XP strip
	var need: float = game.xp_need()
	var xp: float = game.xp
	draw_rect(Rect2(0, 0, size.x, 7), Color(0.03, 0.04, 0.09, 0.85))
	draw_rect(Rect2(0, 0, size.x * clampf(xp / need, 0.0, 1.0), 5), Color(0.4, 0.85, 1.0))
	draw_rect(Rect2(0, 0, size.x * clampf(xp / need, 0.0, 1.0), 2), Color(0.8, 0.97, 1.0))

	# ---- status panel
	var o := Vector2(PAD, 14.0)
	draw_style_box(_bg, Rect2(o, Vector2(W, H)))
	var x := o.x + 12.0
	var y := o.y + 6.0
	var right := o.x + W - 12.0
	var round_no: int = game.round_no
	var w := _text(Vector2(x, y), "ROUND %d" % round_no, 30, PixelUI.GOLD)
	var ev: String = game.round_event
	if ev != "":
		var e: Array = game.EVENTS[ev]
		_text(Vector2(x + w + 8.0, y + 8.0), str(e[0]), 20, e[2])
	var lvl: int = game.level
	_text(Vector2(x, y + 4.0), "LV %d" % lvl, 22, Color(0.5, 0.88, 1.0), HORIZONTAL_ALIGNMENT_RIGHT, right - x)

	# wave progress / build timer / boss
	y += 34.0
	var bar := Rect2(x, y + 4.0, 168.0, 9.0)
	var note := ""
	match st:
		"prep":
			var pt: float = game._prep_t
			var pmax: float = game._prep_max
			_bar(bar, pt / maxf(pmax, 0.1), PixelUI.GOLD)
			note = "build  %ds" % ceili(pt)
		"waves":
			var total: int = game.wave_total
			var left: int = game.mobs.size() + game.to_spawn + game.portals_open
			_bar(bar, 1.0 - float(left) / maxf(total, 1.0), Color(0.5, 0.95, 0.55))
			note = "%d left" % left
		"boss_wait", "boss":
			_bar(bar, 1.0, Color(0.95, 0.3, 0.3) if int(Time.get_ticks_msec() / 300.0) % 2 == 0 else Color(0.75, 0.2, 0.25))
			note = "BOSS"
		_:
			_bar(bar, 1.0, Color(0.5, 0.95, 0.55))
			note = "cleared"
	_text(Vector2(bar.end.x + 8.0, y - 2.0), note, 20, PixelUI.CREAM)

	# coins, kills, threat
	y += 20.0
	draw_texture_rect(icon("ico_coin"), Rect2(x, y + 2.0, 20, 20), false)
	w = _text(Vector2(x + 24.0, y), str(SurvivalArsenal.coins()), 24, PixelUI.GOLD)
	var kx := maxf(x + 24.0 + w + 12.0, x + 92.0)
	draw_texture_rect(icon("ico_skull"), Rect2(kx, y + 2.0, 20, 20), false)
	var kills: int = game.kills
	_text(Vector2(kx + 24.0, y), str(kills), 24, PixelUI.CREAM)

	# weapon slots
	y += 28.0
	var weapons: Array = game.weapons
	var n := maxi(weapons.size(), 1)
	var gap := 4.0
	var s := minf(36.0, (right - x - gap * (n - 1)) / n)
	var cur: String = game.weapon_id()
	var ammo: Dictionary = game.ammo
	for i in weapons.size():
		var id := str(weapons[i])
		var r := Rect2(x + i * (s + gap), y, s, s)
		draw_style_box(_slot_on if id == cur else _slot, r)
		draw_texture_rect(icon("wpn_" + id), r.grow(-4.0), false, Color.WHITE if id == cur else Color(1, 1, 1, 0.55))
		if ammo.has(id):
			_text(Vector2(r.position.x, r.end.y - 14.0), str(int(ammo[id])), 16, Color(0.6, 1.0, 0.7), HORIZONTAL_ALIGNMENT_RIGHT, s - 2.0)
		elif id == cur:
			_text(Vector2(r.position.x, r.end.y - 14.0), "L%d" % SurvivalArsenal.level(id), 16, PixelUI.CREAM, HORIZONTAL_ALIGNMENT_RIGHT, s - 2.0)

	# dash + buffs
	y += 40.0
	var dash_t: float = game._dash_t
	var dash_cd: float = game.stats.dash_cd
	_text(Vector2(x, y - 2.0), "DASH", 18, Color(0.55, 0.9, 1.0) if dash_t <= 0.0 else PixelUI.MUTED)
	_bar(Rect2(x + 40.0, y + 5.0, 52.0, 7.0), 1.0 - dash_t / dash_cd, Color(0.45, 0.9, 1.0) if dash_t <= 0.0 else Color(0.3, 0.45, 0.6))
	var bx := x + 104.0
	var buffs := [["perk_rate", game._rage_t], ["item_potion_shield", game._shield_t],
		["item_potion_speed", game._speed_t], ["item_potion_power", game._power_t]]
	for b in buffs:
		var left_t: float = b[1]
		if left_t > 0.0:
			draw_texture_rect(icon(str(b[0])), Rect2(bx, y - 1.0, 20, 20), false)
			bx += 22.0 + _text(Vector2(bx + 22.0, y - 1.0), str(ceili(left_t)), 20, PixelUI.CREAM) + 8.0

	# score + threat
	y += 22.0
	var score: int = game.score
	_text(Vector2(x, y), "score %d" % score, 20, PixelUI.MUTED)
	var threat: float = game.threat
	_text(Vector2(x, y), "threat x%.2f" % threat, 20,
		Color(0.55, 1.0, 0.6).lerp(Color(1.0, 0.4, 0.35), clampf((threat - 0.8) / 1.6, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_RIGHT, right - x)

	# ---- combo (top right, under the hearts / pause button)
	var combo: int = game.combo
	if combo >= 3:
		var heat := clampf(combo / 40.0, 0.0, 1.0)
		var col := Color(1.0, 0.92, 0.5).lerp(Color(1.0, 0.4, 0.25), heat)
		var cy := 156.0 if Screen.is_touch else 72.0
		var sz := 46 + (8 if _combo_pop > 0.0 else 0)
		_text(Vector2(size.x - 220.0, cy), "x%d" % combo, sz, col, HORIZONTAL_ALIGNMENT_RIGHT, 200.0)
		_text(Vector2(size.x - 220.0, cy + 46.0), "COMBO", 20, PixelUI.CREAM, HORIZONTAL_ALIGNMENT_RIGHT, 200.0)
		var ct: float = game._combo_t
		_bar(Rect2(size.x - 100.0, cy + 70.0, 80.0, 5.0), ct / 3.5, col)
