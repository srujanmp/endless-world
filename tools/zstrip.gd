# Depth-sort check: walks the hero down through a few props in small steps and saves one
# shot per step. A red line marks the hero's sort line, a blue line the prop's.
#   godot --path . res://tools/zstrip.tscn -- --surv-bot --surv-god --out=DIR [--bias=N]
extends Node


func _ready() -> void:
	var s := Stepper.new()
	get_tree().root.add_child.call_deferred(s)


class Marks extends Node2D:
	var hero_y := 0.0
	var prop_y := 0.0
	var x := 0.0
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		draw_line(Vector2(x - 40, hero_y), Vector2(x - 14, hero_y), Color.RED, 1.0)
		draw_line(Vector2(x + 14, prop_y), Vector2(x + 40, prop_y), Color.CYAN, 1.0)


class Stepper extends Node:
	var out := "user://zstrip"
	var bias := INF

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--out="):
				out = a.get_slice("=", 1)
			if a.begins_with("--bias="):
				bias = float(a.get_slice("=", 1))
		DirAccess.make_dir_recursive_absolute(out)
		_run()

	func secs(t: float) -> void:
		await get_tree().create_timer(t, true, false, true).timeout

	func _run() -> void:
		get_tree().change_scene_to_file("res://survival/survival.tscn")
		await secs(2.0)
		var g: Node = get_tree().current_scene
		g.state = "prep"
		g._prep_t = 9999.0
		if bias != INF:
			g.player.depth_bias = bias
		print("ZSTRIP bias=", g.player.depth_bias, " extents=", (g.player.collider.shape as RectangleShape2D).extents,
			" sprite pos=", g.player.get_node("AnimatedSprite2D").position, " scale=", g.player.get_node("AnimatedSprite2D").scale,
			" player scale=", g.player.scale)
		var marks := Marks.new()
		marks.z_index = 4096
		g.add_child(marks)
		var seen := {}
		for c in g.get_children():
			if not (c is Sprite2D) or c.texture == null:
				continue
			var kind: String = c.texture.resource_path.get_file().get_basename()
			var key := "tree" if c.texture.resource_path.contains("/trees/") else kind
			if seen.has(key) or not (key in ["tree", "prop_bush", "prop_pillar", "prop_rock1"]):
				continue
			seen[key] = true
			var i := 0
			for dy in [-28, -20, -14, -10, -6, -2, 2, 6]:
				g.player.position = c.position + Vector2(0, dy)
				g.player.velocity = Vector2.ZERO
				get_viewport().get_camera_2d().reset_smoothing()
				await secs(0.3)
				marks.x = c.position.x
				marks.prop_y = c.position.y
				marks.hero_y = g.player.z_index * 2.0   # the y its z stands for
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(out.path_join("%s_%d.png" % [key, i]))
				print("ZSTRIP ", key, " dy=", dy, " hero z=", g.player.z_index, " prop z=", c.z_index)
				i += 1
		get_tree().quit()
