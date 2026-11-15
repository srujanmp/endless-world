# Takes Survival screenshots for checking how things look (needs a real window, so it
# is not part of CI):
#   godot --path . res://tools/screenshot.tscn -- --surv-bot --surv-god --out=C:/some/dir
# Shots: start, depth sorting around props / trees (player behind and in front), the
# shore, a fight, night, and the perk page.
extends Node


func _ready() -> void:
	var s := Shooter.new()
	get_tree().root.add_child.call_deferred(s)


class Shooter extends Node:
	var out := "user://shots"

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--out="):
				out = a.get_slice("=", 1)
		DirAccess.make_dir_recursive_absolute(out)
		_run()

	func secs(t: float) -> void:
		await get_tree().create_timer(t, true, false, true).timeout

	func snap(name: String) -> void:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
		print("SHOT ", name)

	func go(g: Node, at: Vector2) -> void:
		g.player.position = at
		g.player.velocity = Vector2.ZERO
		var cam := get_viewport().get_camera_2d()
		if cam:
			cam.reset_smoothing()
		await secs(0.35)

	func _run() -> void:
		get_tree().change_scene_to_file("res://survival/survival.tscn")
		await secs(2.0)
		var g: Node = get_tree().current_scene
		await snap("01_start")
		# depth sorting: stand just behind, then just in front of a few things
		var seen := {}
		for c in g.get_children():
			if not (c is Sprite2D) or c.texture == null:
				continue
			var kind: String = c.texture.resource_path.get_file().get_basename()
			var key := "tree" if c.texture.resource_path.contains("/trees/") else kind
			if seen.has(key) or not (key == "tree" or key in ["prop_bush", "prop_pillar", "prop_rock1", "prop_tent", "prop_ruin"]):
				continue
			seen[key] = true
			await go(g, c.position + Vector2(0, -22))
			await snap("z_%s_behind" % key)
			await go(g, c.position + Vector2(0, -8))
			await snap("z_%s_overlap" % key)
			await go(g, c.position + Vector2(0, 4))
			await snap("z_%s_front" % key)
		# the shore: as far left / down as the land goes
		var lo: Vector2i = g.walk_cells[0]
		var hi: Vector2i = g.walk_cells[0]
		for cell in g.walk_cells:
			if cell.x < lo.x:
				lo = cell
			if cell.y > hi.y:
				hi = cell
		await go(g, (Vector2(lo) + Vector2(0.5, 0.5)) * 16.0)
		await snap("shore_left")
		await go(g, (Vector2(hi) + Vector2(0.5, 0.5)) * 16.0)
		await snap("shore_bottom")
		if not g._bridge_cells.is_empty():
			var bc: Vector2i = g._bridge_cells.keys()[0]
			await go(g, (Vector2(bc) + Vector2(0.5, 0.0)) * 16.0)
			await snap("bridge")
		await go(g, g._island_center())
		var cam := get_viewport().get_camera_2d()
		cam.zoom = Vector2(0.3, 0.3)   # the whole island
		await secs(0.4)
		await snap("overview")
		cam.zoom = Vector2.ONE
		for t in ["zombie", "skeleton", "eye", "hornet", "slime", "golem", "knight", "drake"]:
			g.portal(t, g.near_player(50.0, 90.0), ["Giant"] as Array[String])
		g.call_troopers(2)
		g._spawn_ally("medic", g.near_player(30.0, 40.0))
		await secs(2.5)
		await snap("fight")
		for i in mini(4, g.BOSSES.size()):
			for m in g.mobs.duplicate():
				if is_instance_valid(m):
					m.queue_free()
			g.mobs.clear()
			g.boss = null
			g.state = "boss_wait"
			g.round_no = [1, 2, 3, 7][i]
			g._spawn_boss()
			await secs(1.2)
			await snap("boss_%d" % g.round_no)
		g._day_t = 0.0
		await secs(1.5)
		await snap("night")
		g._bot = false
		g._show_upgrades()
		await secs(0.6)
		await snap("perks")
		get_tree().quit()
