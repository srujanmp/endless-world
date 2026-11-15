extends Node2D
class_name SurvivalMachine

# Something the player built on the island (Build menu, B). Turrets shoot the nearest
# monster, the minter makes coins, barricades block walkers. Siege monsters, sappers
# and thieves go after them. Positions are arena-local; the origin is the footprint centre.

const TILE := 16.0
const DEFS := {
	"turret": {"name": "Bolt Turret", "cost": 60, "hp": 24.0, "size": 2, "range": 150.0, "cd": 0.55, "dmg": 1.0,
		"desc": "Shoots the nearest monster."},
	"wall": {"name": "Barricade", "cost": 15, "hp": 40.0, "size": 1, "desc": "Blocks walking monsters."},
	"spikes": {"name": "Spike Trap", "cost": 35, "hp": 1.0, "size": 1, "trap": true, "cd": 0.5, "dmg": 1.0,
		"desc": "Hurts monsters that walk over it."},
	"minter": {"name": "Coin Minter", "cost": 80, "hp": 20.0, "size": 2, "cd": 6.0, "yield": 3, "cap": 45,
		"desc": "Makes coins: walk by to collect. Thieves love it!"},
	"frost": {"name": "Frost Spire", "cost": 90, "hp": 22.0, "size": 2, "range": 90.0, "cd": 0.5,
		"desc": "Slows every monster near it."},
	"cannon": {"name": "Mortar", "cost": 110, "hp": 30.0, "size": 2, "range": 210.0, "cd": 2.2, "dmg": 3.0, "radius": 40.0,
		"desc": "Lobs exploding shells at groups."},
	"totem": {"name": "Healing Totem", "cost": 100, "hp": 20.0, "size": 2, "range": 70.0, "cd": 9.0,
		"desc": "Heals you 1 heart every 9 s nearby."},
	"tesla": {"name": "Tesla Coil", "cost": 140, "hp": 26.0, "size": 2, "range": 125.0, "cd": 1.3, "dmg": 1.6, "chains": 3,
		"desc": "Lightning that jumps between monsters."},
}
const ORDER := ["turret", "wall", "spikes", "minter", "frost", "cannon", "totem", "tesla"]
const DEFENSES := ["turret", "cannon", "tesla", "frost"]
const FONT := preload("res://assets/fonts/Jersey10-Regular.ttf")

var game: Node                  # SurvivalGame
var id := ""
var def: Dictionary
var hp := 1.0
var max_hp := 1.0
var cells: Array[Vector2i] = []
var stored := 0                 # minter: coins waiting to be picked up (or stolen)
var cd := 0.6
var aim := Vector2.RIGHT
var spr: Sprite2D
var _t := 0.0
var _flash := 0.0
var _anim := 0.0                # "active" frame shown while > 0
var _lbl: Label


static func sprite_path(mid: String) -> String:
	return "res://assets/survival/build_%s.png" % mid


func setup(g: Node, mid: String, at: Array[Vector2i]) -> void:
	game = g
	id = mid
	def = DEFS[mid]
	cells = at
	max_hp = float(def.hp)
	hp = max_hp
	var n := int(def.size)
	position = (Vector2(at[0]) + Vector2(n, n) * 0.5) * TILE
	z_index = int((position.y + n * TILE * 0.5) / 2.0) - (3 if is_trap() else 0)
	var sh := Sprite2D.new()
	sh.texture = preload("res://assets/wildlife/shadow_soft.png")
	sh.scale = Vector2(0.5, 0.35) * n
	sh.position = Vector2(0, n * TILE * 0.4)
	add_child(sh)
	spr = Sprite2D.new()
	spr.texture = load(sprite_path(mid))
	spr.hframes = 2
	add_child(spr)
	if not is_trap():   # the player can't walk through it
		var body := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(n, n) * TILE * 0.8
		cs.shape = rs
		body.add_child(cs)
		add_child(body)
	if mid == "minter":
		_lbl = Label.new()
		_lbl.add_theme_font_override("font", FONT)
		_lbl.add_theme_font_size_override("font_size", 18)
		_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_lbl.add_theme_constant_override("outline_size", 4)
		_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl.size = Vector2(80, 20)
		_lbl.scale = Vector2(0.5, 0.5)
		_lbl.position = Vector2(-20, -28)
		_lbl.material = SurvivalGame.UNSHADED
		add_child(_lbl)
	spr.scale = Vector2(0.6, 0.6)   # pop in
	create_tween().tween_property(spr, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func is_trap() -> bool:
	return def.get("trap", false)


func is_defense() -> bool:
	return id in DEFENSES


func damage(amount: float) -> void:
	if is_trap() or hp <= 0.0:
		return
	hp -= amount
	_flash = 0.1
	if hp <= 0.0:
		game.machine_destroyed(self)


func _muzzle() -> Vector2:
	return position + Vector2(0, -12)


func _process(delta: float) -> void:
	if game.state in ["intro", "over"]:
		return
	_t += delta
	cd -= delta
	_flash -= delta
	_anim -= delta
	var k: float = game.machine_k()
	match id:
		"turret":
			var m: SurvivalMob = game._nearest_mob(_muzzle(), float(def.range))
			if m:
				aim = (m.center() - _muzzle()).normalized()
				if cd <= 0.0:
					cd = float(def.cd)
					_anim = 0.12
					var s: SurvivalShot = game.shoot(_muzzle() + aim * 9.0, aim * 300.0, float(def.dmg) * k, Color(0.45, 0.95, 1.0), false)
					s.kind = "bolt"
					s.life = 0.9
					game.sfx.play("shoot", 0.3)
		"cannon":
			var m: SurvivalMob = game._nearest_mob(_muzzle(), float(def.range))
			if m and cd <= 0.0:
				cd = float(def.cd)
				_anim = 0.25
				var to: Vector2 = m.center() - _muzzle()
				var s: SurvivalShot = game.shoot(_muzzle(), to.normalized() * 190.0, float(def.dmg) * k, Color(1.0, 0.55, 0.2), false)
				s.kind = "fire"
				s.boom = float(def.radius)
				s.life = to.length() / 190.0   # bursts where the monster stood
				game.sfx.play("boom", 0.3)
		"tesla":
			if cd <= 0.0:
				var first: SurvivalMob = game._nearest_mob(_muzzle(), float(def.range))
				cd = float(def.cd) if first else 0.3
				if first:
					_anim = 0.2
					var pts: Array[Vector2] = [position + Vector2(0, -22)]
					var hit: Array = []
					var cur := first
					for i in int(def.chains):
						if cur == null:
							break
						hit.append(cur)
						pts.append(cur.center())
						cur.hit(float(def.dmg) * k, (cur.center() - pts[pts.size() - 2]).normalized())
						cur = game._nearest_mob(pts.back(), 95.0, hit)
					game._zap(pts)
					game.sfx.play("hit", 0.3)
		"frost":
			if cd <= 0.0:
				cd = float(def.cd)
				for m in game.mobs:
					if is_instance_valid(m) and not m.dead and m.position.distance_to(position) < float(def.range):
						m.slow_t = maxf(m.slow_t, 0.8)
		"minter":
			if cd <= 0.0:
				cd = float(def.cd)
				if stored < int(def.cap):
					stored = mini(int(def.cap), stored + int(def.yield) + game.round_no / 3)
					_anim = 0.3
			if stored > 0 and game.ppos().distance_to(position) < 44.0:
				game.drop_coins(position + Vector2(0, -8), stored)
				stored = 0
			_lbl.text = "🪙 %d" % stored if stored > 0 else ""
		"totem":
			if cd <= 0.0:
				cd = 0.5
				if game.ppos().distance_to(position) < float(def.range) and game.hearts.current_hearts < game.hearts.max_hearts and not game.down:
					cd = float(def.cd)
					_anim = 0.5
					game.hearts.heal(1)
					game.floater(game.ppos() + Vector2(0, -16), "+1 heart", Color(0.5, 1.0, 0.6))
					game.sfx.play("pickup", 0.0)
		"spikes":
			if cd <= 0.0:
				cd = float(def.cd)
				for m in game.mobs.duplicate():
					if is_instance_valid(m) and not m.dead and not m.is_flyer() and absf(m.position.x - position.x) < 10.0 \
							and absf(m.position.y - position.y) < 10.0:
						_anim = 0.3
						m.hit(float(def.dmg) * k, Vector2.ZERO)
	# look
	match id:
		"turret", "cannon", "spikes":
			spr.frame = 1 if _anim > 0.0 else 0
		"wall":
			spr.frame = 1 if hp < max_hp * 0.5 else 0
		_:
			spr.frame = 1 if _anim > 0.0 or int(_t * 2.5) % 2 == 0 else 0
	spr.self_modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE
	queue_redraw()


func _draw() -> void:
	var n := int(def.size)
	if id == "turret":   # the barrel turns to its target
		var b := Vector2(0, -12)
		draw_line(b, b + aim * (9.0 - (2.0 if _anim > 0.0 else 0.0)), Color(0.12, 0.12, 0.18), 4.0)
		draw_line(b, b + aim * (8.0 - (2.0 if _anim > 0.0 else 0.0)), Color(0.55, 0.6, 0.75), 2.0)
	if id == "frost":    # cold aura
		draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.6))
		draw_arc(Vector2.ZERO, float(def.range) * (0.85 + 0.15 * fmod(_t, 1.0)), 0.0, TAU, 40, Color(0.6, 0.9, 1.0, 0.25 * (1.0 - fmod(_t, 1.0))), 1.5)
		draw_set_transform(Vector2.ZERO)
	if game.build_mode and def.has("range") and not is_trap():   # show reach while building
		draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.6))
		draw_arc(Vector2.ZERO, float(def.range), 0.0, TAU, 48, Color(1.0, 0.85, 0.4, 0.35), 1.0)
		draw_set_transform(Vector2.ZERO)
	if hp < max_hp and not is_trap():
		var w := 10.0 * n
		var y := -n * TILE * 0.5 - 6.0
		draw_rect(Rect2(-w * 0.5 - 1, y - 1, w + 2, 4), Color(0.05, 0.05, 0.1, 0.85))
		var f := clampf(hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-w * 0.5, y, w * f, 2), Color(0.4, 1.0, 0.5) if f > 0.5 else (Color(1.0, 0.8, 0.3) if f > 0.25 else Color(1.0, 0.35, 0.3)))
