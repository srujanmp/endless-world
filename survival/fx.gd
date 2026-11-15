class_name SurvivalFx

# Survival eye-candy: glows, blasts, sparks, scorch marks, death pops and the drifting
# motes / fireflies / embers that make the island feel alive. Everything here is
# cosmetic: nothing in this file changes the game's rules.

const GLOW := preload("res://assets/survival/fx_glow.png")
static var ADD := _add_mat()
static var FADE := _fade()
static var BLINK := _blink()


static func _add_mat() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # glows stay bright at night
	return m


static func _fade() -> Gradient:   # particles: solid, then fade out
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	return g


static func _blink() -> Gradient:   # fireflies: fade in, glow, fade out
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.3, Color(1, 1, 1, 1))
	g.add_point(0.7, Color(1, 1, 1, 0.8))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	return g


# A soft additive light blob, `size` world pixels across.
static func glow(col: Color, size: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = GLOW
	s.material = ADD
	s.modulate = col
	s.scale = Vector2.ONE * size / 64.0
	return s


static func blast(parent: Node, at: Vector2, radius: float, col: Color) -> void:
	var b := Blast.new()
	b.position = at
	b.radius = radius
	b.color = col
	b.z_index = 4050
	b.material = SurvivalGame.UNSHADED
	parent.add_child(b)


static func sparks(parent: Node, at: Vector2, col: Color, n := 6, speed := 70.0, dir := Vector2.ZERO) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.z_index = 4060
	p.material = SurvivalGame.UNSHADED
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = Screen.fx_count(n)
	p.lifetime = 0.4
	p.direction = dir if dir != Vector2.ZERO else Vector2.UP
	p.spread = 40.0 if dir != Vector2.ZERO else 180.0
	p.gravity = Vector2(0, 170)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = col
	p.color_ramp = FADE
	p.emitting = true
	parent.add_child(p)
	parent.get_tree().create_timer(0.9).timeout.connect(p.queue_free)


# Burnt ground where something blew up.
static func scorch(parent: Node, at: Vector2, radius: float) -> void:
	var s := Sprite2D.new()
	s.texture = GLOW
	s.modulate = Color(0.06, 0.04, 0.03, 0.6)
	s.scale = Vector2(radius * 2.4, radius * 1.4) / 64.0
	s.position = at
	s.z_index = 1
	parent.add_child(s)
	var tw := s.create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(s, "modulate:a", 0.0, 2.5)
	tw.tween_callback(s.queue_free)


# A dying monster flashes white and squashes flat.
static func pop(parent: Node, m: SurvivalMob) -> void:
	var g := Sprite2D.new()
	g.texture = m.spr.texture
	g.hframes = 2
	g.frame = m.spr.frame
	g.flip_h = m.spr.flip_h
	g.offset = m.spr.offset
	g.scale = m.spr.scale
	g.position = m.position + m.spr.position
	g.z_index = m.z_index
	g.material = SurvivalGame.UNSHADED
	g.modulate = Color(3, 3, 3, 0.9)
	parent.add_child(g)
	var tw := g.create_tween().set_parallel()
	tw.tween_property(g, "scale", g.scale * Vector2(1.6, 0.35), 0.2)
	tw.tween_property(g, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(g.queue_free)


# Drifting specks around whatever they are attached to (the player, so they follow the camera).
static func motes(col: Color, amount: int, firefly: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = Screen.fx_count(amount)
	p.lifetime = 6.0
	p.preprocess = 3.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(360, 210)
	p.spread = 180.0
	p.gravity = Vector2.ZERO if firefly else Vector2(5, 4)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 12.0
	p.color = col
	p.color_ramp = BLINK
	p.z_index = 4040
	if firefly:
		p.texture = GLOW
		p.scale_amount_min = 0.08
		p.scale_amount_max = 0.16
		p.material = ADD
	else:
		p.scale_amount_min = 1.0
		p.scale_amount_max = 2.0
	return p


# Sparks rising from a lava pool.
static func embers() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 5
	p.lifetime = 1.8
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 16.0
	p.direction = Vector2.UP
	p.spread = 25.0
	p.gravity = Vector2(0, -18)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 18.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(1.0, 0.6, 0.2)
	p.color_ramp = FADE
	p.material = SurvivalGame.UNSHADED
	p.z_index = 4040
	return p


# Explosion: white flash, fireball, two shock rings and a burst of light.
class Blast extends Node2D:
	const LIFE := 0.42
	var radius := 40.0
	var color := Color(1.0, 0.6, 0.2)
	var _t := 0.0
	func _ready() -> void:
		var g := SurvivalFx.glow(color, radius * 3.4)
		add_child(g)
		create_tween().tween_property(g, "modulate:a", 0.0, LIFE)
	func _process(delta: float) -> void:
		_t += delta
		if _t > LIFE:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := clampf(_t / LIFE, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)   # shoots out, then eases
		if _t < 0.05:
			draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, 0.7))
		draw_circle(Vector2.ZERO, radius * e, Color(color, 0.4 * (1.0 - k)))
		draw_circle(Vector2.ZERO, radius * 0.55 * (1.0 - k), Color(color.lightened(0.6), 0.85 * (1.0 - k)))
		draw_arc(Vector2.ZERO, radius * e, 0.0, TAU, 32, Color(color.lightened(0.5), 1.0 - k), 2.0)
		draw_arc(Vector2.ZERO, radius * e * 0.68, 0.0, TAU, 24, Color(1, 1, 1, 0.5 * (1.0 - k)), 1.0)
