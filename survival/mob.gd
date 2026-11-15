extends Node2D
class_name SurvivalMob

# A monster in Survival mode: one of 21 types (each with its own AI), optional random
# mutations, or a boss that cycles through attack patterns. Positions are arena-local
# (the arena node is drawn at 2x), the origin is at the feet. Health scales with the
# round, your firepower and the dynamic threat level (SurvivalGame.hp_mult).

const TYPES := {
	# "art": sprite file when it isn't the type name (redrawn HD art; the 16px originals stay
	# for the coding-quest pictures)
	"zombie":   {"hp": 4.0, "speed": 36.0, "dmg": 1, "r": 7.0, "scale": 1.6, "ai": "chase", "pts": 10},
	"bat":      {"hp": 2.0, "speed": 82.0, "dmg": 1, "r": 6.0, "scale": 1.4, "ai": "erratic", "pts": 12, "art": "bat_hd"},
	"slime":    {"hp": 5.0, "speed": 30.0, "dmg": 1, "r": 8.0, "scale": 1.6, "ai": "hop", "pts": 12},
	"skeleton": {"hp": 3.0, "speed": 34.0, "dmg": 1, "r": 7.0, "scale": 1.6, "ai": "archer", "pts": 15},
	"spider":   {"hp": 3.0, "speed": 44.0, "dmg": 1, "r": 7.0, "scale": 1.6, "ai": "lunge", "pts": 14, "art": "spider_hd"},
	"wolf":     {"hp": 3.0, "speed": 70.0, "dmg": 1, "r": 7.0, "scale": 1.6, "ai": "wolf", "pts": 12, "art": "wolf_hd"},
	"ghost":    {"hp": 3.0, "speed": 48.0, "dmg": 1, "r": 7.0, "scale": 1.6, "ai": "phase", "pts": 16, "art": "ghost_hd"},
	"bomber":   {"hp": 3.0, "speed": 52.0, "dmg": 2, "r": 7.0, "scale": 1.6, "ai": "bomber", "pts": 15, "art": "bomber_hd"},
	"mage":     {"hp": 4.0, "speed": 30.0, "dmg": 1, "r": 7.0, "scale": 1.7, "ai": "mage", "pts": 20, "art": "mage_hd"},
	"golem":    {"hp": 12.0, "speed": 22.0, "dmg": 2, "r": 11.0, "scale": 2.2, "ai": "chase", "pts": 30, "art": "golem_hd"},
	"eye":      {"hp": 3.0, "speed": 58.0, "dmg": 1, "r": 7.0, "scale": 1.6, "ai": "eye", "pts": 14, "fly": true},
	"hornet":   {"hp": 2.5, "speed": 56.0, "dmg": 1, "r": 6.0, "scale": 1.5, "ai": "hornet", "pts": 16, "fly": true},
	"raider":   {"hp": 5.0, "speed": 44.0, "dmg": 1, "r": 7.0, "scale": 1.6, "ai": "lunge", "pts": 14},
	"goblin":   {"hp": 3.0, "speed": 64.0, "dmg": 1, "r": 6.0, "scale": 1.5, "ai": "thief", "pts": 16, "steal": 8},
	"coin_golem": {"hp": 22.0, "speed": 26.0, "dmg": 2, "r": 10.0, "scale": 2.2, "ai": "thief", "pts": 40, "steal": 25},
	"brute":    {"hp": 18.0, "speed": 24.0, "dmg": 2, "r": 10.0, "scale": 2.3, "ai": "siege", "pts": 35},
	"sapper":   {"hp": 3.0, "speed": 58.0, "dmg": 2, "r": 7.0, "scale": 1.6, "ai": "sapper", "pts": 18},
	"shaman":   {"hp": 5.0, "speed": 40.0, "dmg": 1, "r": 7.0, "scale": 1.7, "ai": "healer", "pts": 24},
	"boar":     {"hp": 7.0, "speed": 60.0, "dmg": 2, "r": 8.0, "scale": 1.9, "ai": "charger", "pts": 24, "jump": true},
	"knight":   {"hp": 8.0, "speed": 30.0, "dmg": 1, "r": 7.0, "scale": 1.7, "ai": "chase", "pts": 22, "armor": 0.55},
	"drake":    {"hp": 6.0, "speed": 50.0, "dmg": 1, "r": 8.0, "scale": 1.8, "ai": "drake", "pts": 26},
}
# Unlock order: round N spawns the first 2N + 2 types.
const ORDER := ["zombie", "slime", "raider", "bat", "goblin", "eye", "skeleton", "sapper", "spider", "knight", "hornet",
	"boar", "wolf", "shaman", "ghost", "bomber", "coin_golem", "mage", "drake", "brute", "golem"]
const FLYERS := ["bat", "ghost", "eye", "hornet", "shaman", "drake"]   # cross water and barricades
# Slimes come in many colours (the sprite is pale and tinted per slime).
const SLIME_COLORS := [Color(0.45, 1.0, 0.5), Color(0.45, 0.7, 1.0), Color(1.0, 0.55, 0.8), Color(0.75, 0.5, 1.0),
	Color(1.0, 0.9, 0.35), Color(1.0, 0.45, 0.4), Color(0.4, 1.0, 0.95), Color(0.55, 0.55, 0.65)]
const MUTATIONS := ["Giant", "Swift", "Armored", "Vampiric", "Explosive", "Regenerating", "Splitting", "Phasing", "Burning", "Tiny"]
const MUT_COLOR := {
	"Giant": Color(1.0, 0.75, 0.45), "Swift": Color(1.0, 0.95, 0.4), "Armored": Color(0.75, 0.8, 0.9),
	"Vampiric": Color(1.0, 0.35, 0.4), "Explosive": Color(1.0, 0.55, 0.2), "Regenerating": Color(0.45, 1.0, 0.5),
	"Splitting": Color(0.6, 0.9, 1.0), "Phasing": Color(0.8, 0.7, 1.0), "Burning": Color(1.0, 0.45, 0.15),
	"Tiny": Color(0.9, 0.9, 0.9),
}
const SHADOW := preload("res://assets/wildlife/shadow_soft.png")
const FONT := preload("res://assets/fonts/Jersey10-Regular.ttf")

var game: Node                  # SurvivalGame
var type_name := ""
var kind: Dictionary
var hp := 1.0
var max_hp := 1.0
var speed := 30.0
var radius := 7.0
var dmg := 1
var scale_k := 1.6
var armor := 1.0                # damage multiplier taken
var regen := 0.0
var mutations: Array[String] = []
var tint := Color.WHITE
var is_boss := false
var is_clone := false
var boss: Dictionary = {}
var dead := false

var spr: Sprite2D
var _px := 1.0                  # sprite pixels -> world: 16 px art and 24 px art end up the same size
var tag: Label
var t := randf() * 10.0
var _born := 0.0                # value of t when it appeared (pop-in)
var kb := Vector2.ZERO
var flash := 0.0
var state := ""
var state_t := 0.0
var cd := 1.0                   # attack / ability cooldown
var aim := Vector2.ZERO
var move_dir := Vector2.ZERO
var phased := false
var _fire_drop := 0.0
var _pattern_i := 0
var _spiral_a := 0.0
var _shots_left := 0
var _jump_from := Vector2.ZERO
var enraged := false
# co-op
var net_id := 0                 # id shared with the other players (0 = solo)
var remote := false             # guest-side copy of a monster the host simulates
var net_target := Vector2.ZERO
var _last_x := 0.0
var _stuck_t := 0.0             # walker blocked by water for this long...
var _wade_t := 0.0              # ...so it wades across for a while (no pathfinding needed)
var slow_t := 0.0               # Frost Spire: half speed
var freeze_t := 0.0             # Frost Bomb: frozen solid
var loot := 0                   # thieves: coins they carry (dropped when killed)
var blocked_by: Node = null     # machine in the way this frame (SurvivalMachine)
var _bite := 0.0                # cooldown for hitting machines


func setup(g: Node, tname: String, muts: Array[String], round_no: int, boss_def: Dictionary = {}) -> void:
	game = g
	type_name = tname
	kind = TYPES[tname]
	hp = kind.hp * g.hp_mult()
	armor = float(kind.get("armor", 1.0))
	speed = kind.speed
	radius = kind.r
	dmg = kind.dmg
	scale_k = kind.scale
	if not boss_def.is_empty():
		is_boss = true
		boss = boss_def
		hp = float(boss_def.hp)
		scale_k = float(boss_def.scale)
		radius = 5.5 * scale_k
		speed = float(boss_def.speed)
		dmg = 1 if round_no <= 4 else 2
		tint = boss_def.tint
		cd = 2.0
	elif tname == "slime":
		tint = SLIME_COLORS.pick_random()
		if randf() < 0.3:   # some big slimes (they split when killed)
			scale_k *= 1.35; radius *= 1.35; hp *= 1.6
	for m in muts:
		_mutate(m)
	max_hp = hp
	_born = t

	var sh := Sprite2D.new()
	sh.texture = SHADOW
	sh.scale = Vector2(0.45, 0.4) * scale_k
	sh.position = Vector2(0, 1)
	add_child(sh)
	spr = Sprite2D.new()
	spr.texture = load("res://assets/survival/%s.png" % str(boss_def.get("sprite", kind.get("art", tname))))
	spr.hframes = 2
	var fh := float(spr.texture.get_height())
	_px = 16.0 / fh
	spr.scale = Vector2.ONE * scale_k * _px
	spr.offset = Vector2(0, -fh * 0.5)
	spr.self_modulate = tint
	add_child(spr)
	if not mutations.is_empty():
		tag = Label.new()
		tag.text = " ".join(mutations)
		tag.add_theme_font_override("font", FONT)
		tag.add_theme_font_size_override("font_size", 16)
		tag.add_theme_color_override("font_color", MUT_COLOR[mutations[0]])
		tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		tag.add_theme_constant_override("outline_size", 4)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.size = Vector2(120, 18)
		tag.scale = Vector2(0.5, 0.5)
		tag.position = Vector2(-30, -16 * scale_k - 12)
		add_child(tag)


# Resize (used by clones and split slimes).
func set_size(k: float) -> void:
	scale_k = k
	spr.scale = Vector2.ONE * k * _px


func is_flyer() -> bool:
	return type_name in FLYERS


func _mutate(m: String) -> void:
	mutations.append(m)
	match m:
		"Giant":
			scale_k *= 1.5; radius *= 1.5; hp *= 2.0; speed *= 0.8; dmg += 1
		"Swift":
			speed *= 1.6; tint = tint * Color(1.0, 1.0, 0.7)
		"Armored":
			armor = 0.5; tint = tint * Color(0.75, 0.8, 0.95)
		"Vampiric":
			tint = tint * Color(1.0, 0.6, 0.65)
		"Regenerating":
			regen = 0.5; tint = tint * Color(0.75, 1.0, 0.75)
		"Burning":
			tint = tint * Color(1.0, 0.75, 0.55)
		"Tiny":
			scale_k *= 0.7; radius *= 0.7; hp *= 0.6; speed *= 1.35
		"Phasing":
			tint = tint * Color(0.85, 0.8, 1.0)


func center() -> Vector2:
	return position + Vector2(0, -6.0 * scale_k)


func untouchable() -> bool:
	return dead or phased or state == "vanish"


func hit(amount: float, dir: Vector2, crit := false, from_net := false) -> void:
	if untouchable():
		return
	if remote:   # co-op guest: the host owns this monster's health
		game.report_hit(self, amount, dir, crit)
		flash = 0.09
		game.sfx.play("hit", 0.2)
		var t2 := str(snappedf(amount * armor, 0.1)).trim_suffix(".0")
		game.floater(center(), t2 + "!" if crit else t2, Color(1.0, 0.55, 0.2) if crit else Color(1, 0.95, 0.6))
		return
	var real := amount * armor
	hp -= real
	if type_name == "coin_golem" and randf() < 0.25:   # a walking piggy bank
		game.drop_coins(position, 1)
	flash = 0.09
	game.sfx.play("crit" if crit else "hit", 0.2)
	if crit or not Screen.low():
		SurvivalFx.sparks(game, center(), Color(1.0, 0.6, 0.25) if crit else Color(1.0, 0.95, 0.7), 8 if crit else 4, 90.0, dir)
	if not is_boss and not type_name in ["golem", "brute", "coin_golem", "knight"]:
		kb += dir * (130.0 if crit else 90.0)
	if not from_net:   # a guest's hit already showed its number on their screen
		var txt := str(snappedf(real, 0.1)).trim_suffix(".0")
		game.floater(center(), txt + "!" if crit else txt, Color(1.0, 0.55, 0.2) if crit else Color(1, 0.95, 0.6))
	if hp <= 0.0:
		dead = true
		game.mob_died(self)


# ------------------------------------------------------------------ per-frame AI
func tick(delta: float, ppos: Vector2) -> void:
	t += delta
	cd -= delta
	state_t -= delta
	flash -= delta
	if regen > 0.0:
		hp = minf(max_hp, hp + regen * delta)
	slow_t -= delta
	freeze_t -= delta
	_bite -= delta
	blocked_by = null
	queue_redraw()   # health bar
	if freeze_t > 0.0:   # frozen: no moving, no attacks
		kb = kb.move_toward(Vector2.ZERO, 400.0 * delta)
		spr.self_modulate = Color(0.55, 0.85, 1.4, 0.9)
		return
	var to_p := ppos - position
	var dist := to_p.length()
	var dir := to_p / maxf(dist, 0.001)
	move_dir = Vector2.ZERO
	var spd := speed * (0.5 if slow_t > 0.0 else 1.0)

	if is_boss:
		_boss_tick(delta, ppos, dir, dist)
		spd = speed * (1.25 if enraged else 1.0)
	else:
		match kind.ai:
			"chase":
				move_dir = dir
			"erratic":
				move_dir = dir.rotated(sin(t * 6.0) * 1.2)
			"hop":
				if state == "hop" and state_t > 0.0:
					move_dir = aim; spd = speed * 3.2
				else:
					state = ""
					if cd <= 0.0:
						state = "hop"; state_t = 0.35; aim = dir; cd = 1.1
			"archer":
				move_dir = dir if dist > 150.0 else (-dir if dist < 100.0 else dir.orthogonal() * (1.0 if int(t / 3.0) % 2 == 0 else -1.0))
				if cd <= 0.0 and dist < 260.0:
					cd = 2.2
					game.shoot(center(), dir * 150.0, 1, Color(0.95, 0.92, 0.82))
			"lunge":
				_dash_ai(dir, dist, 120.0, 230.0, 2.5)
				if state == "": move_dir = dir
				elif state == "dash": move_dir = aim; spd = 230.0
			"wolf":
				_dash_ai(dir, dist, 110.0, 210.0, 3.0)
				if state == "":
					move_dir = (dir.orthogonal() + dir * (0.6 if dist > 90.0 else -0.4)).normalized()
				elif state == "dash":
					move_dir = aim; spd = 210.0
			"phase":
				move_dir = dir
				if cd <= 0.0:
					phased = not phased
					cd = 1.0 if phased else 2.2
				if phased: spd = speed * 1.5
			"bomber":
				if state == "fuse":
					if state_t <= 0.0:
						game.explode(position, 46.0, dmg, true, true, self)
						dead = true
						game.mob_died(self, false)
						return
				elif dist < 26.0:
					state = "fuse"; state_t = 0.8
				else:
					move_dir = dir
			"eye":   # circles you, then rams in after a short glare
				_dash_ai(dir, dist, 170.0, 250.0, 2.6)
				if state == "":
					move_dir = (dir.orthogonal() * 0.9 + dir * (0.7 if dist > 80.0 else -0.5)).normalized()
					move_dir = move_dir.rotated(sin(t * 3.0) * 0.4)
				elif state == "dash":
					move_dir = aim; spd = 250.0
			"hornet":   # keeps its distance and fires stingers
				move_dir = dir if dist > 140.0 else (-dir if dist < 90.0 else dir.orthogonal() * (1.0 if int(t / 2.0) % 2 == 0 else -1.0))
				move_dir = (move_dir + Vector2(0, sin(t * 7.0) * 0.4)).normalized()
				if cd <= 0.0 and dist < 240.0:
					cd = 2.4
					var sting: SurvivalShot = game.shoot(center(), dir * 165.0, 1, Color(1.0, 0.85, 0.2))
					sting.r = 2.5
			"thief":
				if _thief(dir, dist, ppos):
					return
				if state == "flee":
					spd *= 1.3
			"siege":   # goes for your machines first
				var mc = game.nearest_machine(position, "")
				move_dir = (mc.position - position).normalized() if mc else dir
				if mc and _reaches(mc):
					move_dir = Vector2.ZERO
					if _bite <= 0.0:
						_bite = 1.2
						mc.damage(4.0)
						game.shake_small()
			"sapper":   # runs a bomb into the nearest machine (or you)
				var mc = game.nearest_machine(position, "")
				if state == "fuse":
					if state_t <= 0.0:
						game.explode(position, 46.0, dmg, true, true, self)
						game.damage_machines(position, 50.0, 12.0)
						dead = true
						game.mob_died(self, false)
						return
				elif (mc and _reaches(mc)) or (mc == null and dist < 26.0):
					state = "fuse"; state_t = 0.6
				else:
					move_dir = (mc.position - position).normalized() if mc else dir
			"healer":   # hides behind the most hurt monster and heals the pack
				var best: SurvivalMob = null
				var worst := 0.95
				for m in game.mobs:
					if m != self and is_instance_valid(m) and not m.dead and not m.is_boss and m.hp / m.max_hp < worst \
							and m.position.distance_to(position) < 240.0:
						worst = m.hp / m.max_hp
						best = m
				if dist < 110.0:
					move_dir = -dir
				elif best:
					move_dir = (best.position - position).normalized() if best.position.distance_to(position) > 30.0 else dir.orthogonal()
				else:
					move_dir = dir.orthogonal() * (1.0 if int(t / 3.0) % 2 == 0 else -1.0)
				if cd <= 0.0:
					cd = 2.2
					var healed := false
					for m in game.mobs:
						if m != self and is_instance_valid(m) and not m.dead and not m.is_boss and m.hp < m.max_hp \
								and m.position.distance_to(position) < 75.0:
							m.hp = minf(m.max_hp, m.hp + m.max_hp * 0.2)
							healed = true
					if healed:
						game.pulse(center(), 75.0, Color(0.4, 1.0, 0.6))
			"charger":   # rides at your defenses, leaping over barricades
				var mc = game.nearest_machine(position, "defense")
				var goal: Vector2 = mc.position if mc else ppos
				var gd := position.distance_to(goal)
				var gdir := (goal - position) / maxf(gd, 0.001)
				_dash_ai(gdir, gd, 140.0, 240.0, 2.6)
				if state == "": move_dir = gdir
				elif state == "dash": move_dir = aim; spd = 240.0
				if mc and _reaches(mc) and _bite <= 0.0:
					_bite = 0.9
					mc.damage(5.0)
			"drake":   # circles at range, breathes fire
				move_dir = dir if dist > 150.0 else (-dir if dist < 100.0 else dir.orthogonal() * (1.0 if int(t / 2.5) % 2 == 0 else -1.0))
				if cd <= 0.0 and dist < 230.0:
					cd = 2.8
					game.fan(center(), dir, 3, 0.2, 130.0, 1, Color(1.0, 0.5, 0.15))
					if randf() < 0.5:
						game.fire(position + dir * 20.0)
			"mage":
				if state == "vanish":
					if state_t <= 0.0:
						position = game.near_player(110.0, 150.0)
						state = ""
						game.fan(center(), dir, 3, 0.25, 120.0, 1, Color(0.75, 0.45, 1.0))
				else:
					move_dir = dir.orthogonal() * (1.0 if int(t / 2.5) % 2 == 0 else -1.0) + (dir if dist > 150.0 else -dir * 0.5)
					move_dir = move_dir.normalized()
					if cd <= 0.0:
						state = "vanish"; state_t = 0.35; cd = 3.5
	if "Phasing" in mutations:
		phased = fmod(t, 3.0) > 2.0
	if "Burning" in mutations:
		_fire_drop -= delta
		if _fire_drop <= 0.0:
			_fire_drop = 0.6
			game.fire(position)

	# walkers slide along the shore; flyers and bosses may cross water
	var next := position + (move_dir * spd + kb) * delta
	_wade_t -= delta
	if is_flyer() or is_boss:
		position = game.clamp_box(next)
	elif _wade_t > 0.0:
		position = game.clamp_box(position + (move_dir * spd * 0.6 + kb) * delta)
	else:
		var before := position
		position = game.mob_step(self, position, next)
		if blocked_by and is_instance_valid(blocked_by):   # a machine is in the way: smash it
			if _bite <= 0.0:
				_bite = 0.9
				blocked_by.damage(float(dmg))
		# barely moving although it wants to: a pond or bay is in the way
		elif move_dir != Vector2.ZERO and position.distance_to(before) < spd * delta * 0.3:
			_stuck_t += delta
			if _stuck_t > 0.8:
				_stuck_t = 0.0
				_wade_t = 2.5
		else:
			_stuck_t = maxf(0.0, _stuck_t - delta)
	kb = kb.move_toward(Vector2.ZERO, 400.0 * delta)

	# look
	spr.frame = int(t * 5.0) % 2
	if absf(move_dir.x) > 0.05:
		spr.flip_h = move_dir.x < 0.0
	var a := 0.3 if (phased or state == "vanish") else 1.0
	var c := Color(3, 3, 3) if flash > 0.0 else (tint * Color(0.75, 0.9, 1.2) if slow_t > 0.0 else tint)
	if state in ["fuse", "tele_dash", "tele_charge"] and int(t * 12.0) % 2 == 0:
		c = Color(2.5, 0.6, 0.6)
	if enraged:
		c = c * Color(1.25, 0.8, 0.8)
	spr.self_modulate = Color(c, a)
	_squash(move_dir != Vector2.ZERO)
	if state == "hop" or state == "slam":
		spr.position.y = -sin(clampf(1.0 - state_t / (0.9 if state == "slam" else 0.35), 0.0, 1.0) * PI) * (40.0 if state == "slam" else 6.0)
	elif is_flyer():
		spr.position.y = -4.0 + sin(t * 5.0) * 1.5   # hover
	else:
		spr.position.y = 0.0
	z_index = int(position.y * 2.0 / 4.0)
	if tag:   # mutation names only near the player, so big swarms stay readable
		tag.visible = dist < 140.0


# Co-op guests: glide to the host's position and animate locally (no AI here).
func puppet_tick(delta: float) -> void:
	t += delta
	flash -= delta
	position = position.lerp(net_target, clampf(delta * 12.0, 0.0, 1.0))
	var dx := position.x - _last_x
	_last_x = position.x
	if absf(dx) > 0.05:
		spr.flip_h = dx < 0.0
	spr.frame = int(t * 5.0) % 2
	queue_redraw()
	var c := Color(3, 3, 3) if flash > 0.0 else tint
	if state == "tele_dash" and int(t * 12.0) % 2 == 0:
		c = Color(2.5, 0.6, 0.6)
	if enraged:
		c = c * Color(1.25, 0.8, 0.8)
	spr.self_modulate = Color(c, 0.3 if phased else 1.0)
	_squash(true)
	if is_flyer():
		spr.position.y = -4.0 + sin(t * 5.0) * 1.5
	z_index = int(position.y * 2.0 / 4.0)
	if tag:
		tag.visible = position.distance_to(game.ppos()) < 140.0


# Grows in from nothing, bounces as it walks, squashes when hit.
func _squash(moving: bool) -> void:
	var k := scale_k * _px * minf(1.0, (t - _born) / 0.22)
	var a := 0.14 if flash > 0.0 else (sin(t * 11.0) * 0.05 if moving else sin(t * 3.0) * 0.02)
	spr.scale = Vector2(k * (1.0 + a), k * (1.0 - a))


# Aura under mutated monsters and bosses, and a small health bar once hurt
# (tough monsters take a while to bring down).
func _draw() -> void:
	if is_boss or not mutations.is_empty():
		var col: Color = boss.shot if is_boss else MUT_COLOR[mutations[0]]
		var rr := radius * (1.5 + 0.12 * sin(t * 4.0))
		draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, rr, Color(col, 0.16))
		draw_arc(Vector2.ZERO, rr, t * 2.0, t * 2.0 + 4.4, 24, Color(col, 0.7), 1.5)
		draw_set_transform(Vector2.ZERO)
	if is_boss or hp >= max_hp or hp <= 0.0:
		return
	var w := 8.0 + 3.0 * scale_k
	var y := -16.0 * scale_k - 4.0
	draw_rect(Rect2(-w * 0.5 - 0.5, y - 0.5, w + 1.0, 3.0), Color(0.05, 0.04, 0.08, 0.8))
	var f := clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-w * 0.5, y, w * f, 2.0), Color(1.0, 0.3, 0.3).lerp(Color(0.5, 1.0, 0.4), f))


func freeze(secs: float) -> void:
	freeze_t = maxf(freeze_t, secs * (0.35 if is_boss else 1.0))


func _reaches(mc: Node) -> bool:
	return position.distance_to(mc.position) < radius + int(mc.def.size) * 8.0 + 5.0


# Goblins and coin golems: grab coins from a Coin Minter (or from you), then run for it.
# Returns true when it got away (and is gone).
func _thief(dir: Vector2, dist: float, ppos: Vector2) -> bool:
	if state == "flee":
		move_dir = -dir
		if state_t <= 0.0:
			game.mob_escaped(self)
			return true
		return false
	var mc = game.nearest_machine(position, "minter")
	if mc:
		move_dir = (mc.position - position).normalized()
		if _reaches(mc):
			loot += mc.stored
			game.floater(mc.position + Vector2(0, -20), "-%d 🪙 stolen!" % mc.stored, Color(1.0, 0.5, 0.3))
			mc.stored = 0
			state = "flee"; state_t = 7.0
	else:
		move_dir = dir
		# co-op: only the host's own wallet is here to steal from
		if dist < radius + 10.0 and game.ppos().distance_to(ppos) < 2.0 and _bite <= 0.0:
			_bite = 1.0
			var got: int = game.steal_coins(int(kind.steal) + game.round_no)
			if got > 0:
				loot += got
				state = "flee"; state_t = 7.0
	return false


# telegraph, then dash at the player (spiders, wolves)
func _dash_ai(dir: Vector2, dist: float, rng: float, _spd: float, every: float) -> void:
	if state == "tele_dash":
		if state_t <= 0.0:
			state = "dash"; state_t = 0.4
	elif state == "dash":
		if state_t <= 0.0:
			state = ""
	elif cd <= 0.0 and dist < rng:
		state = "tele_dash"; state_t = 0.4; aim = dir; cd = every


# ------------------------------------------------------------------ bosses
func _boss_tick(delta: float, ppos: Vector2, dir: Vector2, dist: float) -> void:
	if not enraged and hp < max_hp * 0.5:
		enraged = true
		game.banner("%s is enraged!" % boss.name, Color(1.0, 0.45, 0.35))
		game.sfx.play("boss", 0.0)
		game.shake()
	match state:
		"":
			move_dir = dir if dist > 70.0 else dir.orthogonal()
			if cd <= 0.0:
				var patterns: Array = boss.patterns
				_start_pattern(str(patterns[_pattern_i % patterns.size()]), dir, ppos)
				_pattern_i += 1
		"spiral":
			if fmod(state_t, 0.13) < delta:
				for k in 2:
					game.shoot(center(), Vector2.RIGHT.rotated(_spiral_a + k * PI) * 90.0, 1, boss.shot)
				_spiral_a += 0.4
			if state_t <= 0.0: _end_pattern()
		"aimed":
			if _shots_left > 0 and fmod(state_t, 0.2) < delta:
				game.fan(center(), dir, 3, 0.16, 140.0, 1, boss.shot)
				_shots_left -= 1
			if state_t <= 0.0: _end_pattern()
		"tele_charge":
			if state_t <= 0.0:
				state = "charge"; state_t = 0.7
		"charge":
			move_dir = aim
			position = game.clamp_box(position + aim * 220.0 * delta)
			if state_t <= 0.0: _end_pattern()
		"slam":
			var k := clampf(1.0 - state_t / 0.9, 0.0, 1.0)
			position = _jump_from.lerp(aim, k)
			if state_t <= 0.0:
				game.ring(center(), 10, 85.0, 1, boss.shot)
				game.explode(position, 40.0, 1, true, false, self)
				game.shake()
				_end_pattern()
		"vanish":
			if state_t <= 0.0:
				position = game.near_player(100.0, 130.0)
				game.ring(center(), 8, 85.0, 1, boss.shot)
				_end_pattern()
		"trail":
			move_dir = dir
			position += dir * speed * 1.2 * delta
			if fmod(state_t, 0.15) < delta:
				game.fire(position)
			if state_t <= 0.0: _end_pattern()


func _start_pattern(p: String, dir: Vector2, ppos: Vector2) -> void:
	var c: Color = boss.shot
	match p:
		"ring":
			game.ring(center(), 10 + mini(game.round_no, 8) / 2, 85.0, 1, c); _end_pattern()
		"spread":
			game.fan(center(), dir, 5, 0.24, 120.0, 1, c); _end_pattern()
		"spiral":
			state = "spiral"; state_t = 1.4
		"aimed":
			state = "aimed"; state_t = 0.6; _shots_left = 3
		"charge":
			state = "tele_charge"; state_t = 0.85; aim = dir
			game.telegraph_line(position, dir, 180.0, 0.85)
		"slam":
			state = "slam"; state_t = 0.9; _jump_from = position; aim = game.clamp_arena(ppos)
			game.telegraph(aim, 40.0, 0.9)
		"summon":
			if game.mobs.size() > 6:   # enough helpers already: no endless minion flood
				game.ring(center(), 8, 85.0, 1, c); _end_pattern()
				return
			for k in 2:
				game.portal(boss.minion, game.near(position, 30.0, 60.0), [] as Array[String])
			_end_pattern()
		"teleport":
			state = "vanish"; state_t = 0.45
		"trail":
			state = "trail"; state_t = 3.0
		"web":
			for k in 3:
				var s: SurvivalShot = game.shoot(center(), dir.rotated((k - 1) * 0.3) * 90.0, 0, Color(0.92, 0.92, 1.0))
				s.slows = true; s.r = 5.0
			_end_pattern()
		"homing":
			for k in 3:
				var s: SurvivalShot = game.shoot(center(), dir.rotated((k - 1) * 0.8) * 80.0, 1, Color(0.6, 1.0, 0.6))
				s.homing = 2.2; s.life = 4.0; s.r = 4.0
			_end_pattern()
		"clones":
			if game.mobs.size() > 5:
				game.fan(center(), dir, 5, 0.24, 120.0, 1, c); _end_pattern()
				return
			for k in 2:
				game.clone_of(self)
			_end_pattern()
		_:
			_end_pattern()


func _end_pattern() -> void:
	state = ""
	cd = 2.2 if enraged else 3.0   # breathing room between attacks
