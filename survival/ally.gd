extends Node2D
class_name SurvivalAlly

# Friendly folk in Survival:
#   trooper  parachutes in (flare, crate, loadout), shoots monsters for a while
#   trader   lives on the island; stand next to them and press T to shop
#   medic    drops in every 3rd round, follows you and patches you up
# Monsters don't chase them, but bumping into one hurts a trooper.

const SHADOW := preload("res://assets/wildlife/shadow_soft.png")
const FONT := preload("res://assets/fonts/Jersey10-Regular.ttf")
const DROP_H := 220.0

var game: Node                  # SurvivalGame
var kind := "trooper"
var hp := 6.0
var max_hp := 6.0
var life := 40.0
var drop := 0.0                 # height above ground while parachuting
var home := Vector2.ZERO
var spr: Sprite2D
var tag: Label
var _t := randf() * 5.0
var _cd := 0.5
var _hurt_cd := 0.0
var _flash := 0.0
var _goal := Vector2.ZERO
var _aim := Vector2.RIGHT
var _gone := false


func setup(g: Node, k: String, at: Vector2, from_sky := false) -> void:
	game = g
	kind = k
	position = at
	home = at
	_goal = at
	if from_sky:
		drop = DROP_H
	match kind:
		"trooper":
			max_hp = 6.0 + game.round_no * 0.6
			life = 40.0
		"medic":
			max_hp = 999.0
			life = 150.0
			_cd = 6.0
		"trader":
			max_hp = 999.0
			life = INF
	hp = max_hp
	var sh := Sprite2D.new()
	sh.texture = SHADOW
	sh.scale = Vector2(0.7, 0.6)
	sh.position = Vector2(0, 1)
	add_child(sh)
	spr = Sprite2D.new()
	spr.texture = load("res://assets/survival/%s.png" % kind)
	spr.hframes = 2
	spr.scale = Vector2.ONE * 1.6 * 16.0 / 24.0
	spr.offset = Vector2(0, -12)
	add_child(spr)
	tag = Label.new()
	tag.text = {"trooper": "Trooper", "medic": "Medic", "trader": "Trader"}[kind]
	tag.add_theme_font_override("font", FONT)
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", Color(0.55, 1.0, 0.75) if kind != "trader" else Color(1.0, 0.85, 0.35))
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	tag.add_theme_constant_override("outline_size", 4)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.size = Vector2(140, 18)
	tag.scale = Vector2(0.5, 0.5)
	tag.position = Vector2(-35, -36)
	tag.material = SurvivalGame.UNSHADED
	add_child(tag)


func center() -> Vector2:
	return position + Vector2(0, -10)


func near_player(r := 34.0) -> bool:
	return drop <= 0.0 and game.ppos().distance_to(center()) < r


func _process(delta: float) -> void:
	if _gone or game.state in ["intro", "over"]:
		return
	_t += delta
	_flash -= delta
	queue_redraw()
	if drop > 0.0:   # floating down under the canopy
		drop = maxf(0.0, drop - 75.0 * delta)
		spr.position = Vector2(sin(_t * 2.0) * 3.0 * minf(drop / 40.0, 1.0), -drop)
		spr.rotation = sin(_t * 2.0) * 0.12 * minf(drop / 40.0, 1.0)
		tag.position.y = -36.0 - drop
		if drop <= 0.0:
			spr.position = Vector2.ZERO
			spr.rotation = 0.0
			tag.position.y = -36.0
			game._puff(position, Color(0.8, 0.75, 0.6), 0.8)
		return
	_cd -= delta
	_hurt_cd -= delta
	life -= delta
	var move := Vector2.ZERO
	var face := Vector2.ZERO        # look this way instead of where it walks
	var spd := 55.0
	var pp: Vector2 = game.player.position
	match kind:
		"trooper":
			var m: SurvivalMob = game._nearest_mob(center(), 200.0)
			if m:
				var to := m.center() - center()
				_aim = to.normalized()
				face = _aim
				var d := to.length()
				move = _aim if d > 120.0 else (-_aim if d < 60.0 else _aim.orthogonal() * (1.0 if int(_t / 2.0) % 2 == 0 else -1.0))
				if _cd <= 0.0:
					_cd = 0.45
					var s: SurvivalShot = game.shoot(center() + _aim * 8.0, _aim.rotated(randf_range(-0.06, 0.06)) * 340.0,
						0.8 * game.machine_k(), Color(1.0, 0.9, 0.5), false)
					s.kind = "bullet"
					s.life = 0.8
					game.sfx.play("shoot", 0.3)
			elif position.distance_to(pp) > 60.0:
				move = (pp - position).normalized()
			# monsters bumping into troopers hurt them
			if _hurt_cd <= 0.0:
				for mob in game.mobs:
					if is_instance_valid(mob) and not mob.dead and mob.center().distance_to(center()) < mob.radius + 7.0:
						hp -= float(mob.dmg)
						_hurt_cd = 0.8
						_flash = 0.1
						break
			if hp <= 0.0 or life <= 0.0:
				leave("Trooper down!" if hp <= 0.0 else "")
				return
		"medic":
			var want := pp + Vector2(-26 if pp.x > position.x else 26, 6)
			if position.distance_to(want) > 18.0:
				move = (want - position).normalized()
				spd = 90.0 if position.distance_to(pp) > 120.0 else 60.0
			if _cd <= 0.0:
				_cd = 0.5
				if game.hearts.current_hearts < game.hearts.max_hearts and not game.down and position.distance_to(pp) < 60.0:
					_cd = 14.0
					game.hearts.heal(1)
					game.floater(game.ppos() + Vector2(0, -16), "Medic: +1 heart", Color(0.5, 1.0, 0.6))
					game.sfx.play("pickup", 0.0)
			if life <= 0.0:
				leave("The medic heads home")
				return
		"trader":
			spd = 18.0
			if near_player(60.0):
				face = (pp - position).normalized()   # turns to face you
			elif position.distance_to(_goal) < 4.0 or _cd <= 0.0:
				_cd = randf_range(3.0, 6.0)
				_goal = game.near(home, 0.0, 40.0)
			else:
				move = (_goal - position).normalized()
			tag.text = ("[T] Trade" if not Screen.is_touch else "Trader") if near_player(40.0) else "Trader"
	if move != Vector2.ZERO:
		position = game.move_in(position, position + move * spd * delta)
	if face != Vector2.ZERO or move != Vector2.ZERO:
		_aim = face if face != Vector2.ZERO else move
	spr.frame = int(_t * (6.0 if move != Vector2.ZERO else 2.0)) % 2
	if absf(_aim.x) > 0.05:
		spr.flip_h = _aim.x < 0.0
	spr.self_modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE
	z_index = int(position.y / 2.0)


func leave(msg := "") -> void:
	if _gone:
		return
	_gone = true
	game.allies.erase(self)
	game._puff(center(), Color(0.7, 1.0, 0.8), 1.0)
	if msg != "":
		game.banner_small(msg)
	queue_free()


func _draw() -> void:
	if drop > 0.0:   # striped parachute and strings
		var top := Vector2(spr.position.x, -drop - 40.0)
		var a := minf(drop / 30.0, 1.0)
		var stripes := [Color(0.95, 0.95, 0.95, a), Color(0.3, 0.6, 0.35, a)] if kind == "trooper" else [Color(0.95, 0.95, 0.95, a), Color(0.85, 0.25, 0.3, a)]
		for i in 6:
			var a0 := PI + PI * i / 6.0
			var a1 := PI + PI * (i + 1) / 6.0
			draw_colored_polygon(PackedVector2Array([top, top + Vector2(cos(a0) * 20.0, sin(a0) * 13.0),
				top + Vector2(cos(a1) * 20.0, sin(a1) * 13.0)]), stripes[i % 2])
		for x in [-19.0, -7.0, 7.0, 19.0]:
			draw_line(top + Vector2(x, 0), Vector2(spr.position.x, -drop - 14.0), Color(0.2, 0.2, 0.25, 0.7 * a), 0.6)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))   # landing spot
		draw_circle(Vector2.ZERO, 8.0 * (1.0 - drop / DROP_H) + 2.0, Color(0, 0, 0, 0.25))
		return
	if kind == "trooper" and hp < max_hp:
		var f := clampf(hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-8, -30, 16, 3), Color(0.05, 0.05, 0.1, 0.85))
		draw_rect(Rect2(-7.5, -29.5, 15.0 * f, 2), Color(0.45, 1.0, 0.6))
