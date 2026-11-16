extends Node
# Multi-process check of the WebRTC mesh + relay fallback (uses RELAY_URL like the game):
#   godot --headless --path . res://tools/p2p_test.tscn -- --host ABCD 3
#   godot --headless --path . res://tools/p2p_test.tscn -- --join ABCD 3 [--no-p2p]
# Every player streams 200 numbered messages while links switch relay -> direct. Each
# receiver checks every sender's numbers arrive exactly once and in order. Exit 0 = pass.

const COUNT := 200
var players := 2
var sent := 0
var last := {}      # sender id -> last number received
var finished := {}  # sender id -> true once its "fin" arrived
var errors: Array[String] = []
var _tick := 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var host := "--host" in args
	var at := args.find("--host" if host else "--join")
	var code: String = args[at + 1]
	if args.size() > at + 2 and args[at + 2].is_valid_int():
		players = int(args[at + 2])
	if "--no-p2p" in args:
		Net.p2p_available = false
	Net.message.connect(_on_msg)
	Net.disconnected.connect(func(r): if finished.size() < players - 1: _done("disconnected: " + r))
	get_tree().create_timer(90.0).timeout.connect(func(): _done("timeout"))
	if host:
		Net.host_room("Host", code)
	else:
		await get_tree().create_timer(4.0 + randf() * 2.0).timeout   # host first, guests staggered
		Net.join_room(code, "Guest")
	set_process(false)
	await Net.connected
	while Net.peers.size() < players:   # start streaming once everyone is in
		await get_tree().process_frame
	set_process(true)


func _process(delta: float) -> void:
	_tick += delta
	if _tick < 0.05 or sent >= COUNT:
		return
	_tick = 0.0
	sent += 1
	Net.send({"t": "seq", "n": sent, "pad": "x".repeat(randi() % 400)})
	if sent == COUNT:
		Net.send({"t": "fin", "n": COUNT})


func _on_msg(from: int, d: Dictionary) -> void:
	match str(d.get("t", "")):
		"seq":
			var n := int(d.n)
			if last.has(from) and n != last[from] + 1:
				errors.append("#%d: got %d after %d" % [from, n, last[from]])
			last[from] = n
		"fin":
			if int(last.get(from, -1)) != COUNT:
				errors.append("#%d: fin but last was %d" % [from, last.get(from, -1)])
			finished[from] = true
			if finished.size() == players - 1:
				while sent < COUNT:
					await get_tree().process_frame
				await get_tree().create_timer(2.0).timeout   # let my own fin reach everyone
				_done("")


func _done(why: String) -> void:
	var links := []
	for id in Net.peers:
		if id != Net.my_id:
			links.append("#%d %s" % [id, "direct" if Net.is_direct(id) else "relay"])
	if not why.is_empty():
		errors.append(why)
	print("[P2P test] #%d %s  links: %s  %s" % [Net.my_id, "PASS" if errors.is_empty() else "FAIL", ", ".join(links), "; ".join(errors)])
	Net.leave()
	get_tree().quit(0 if errors.is_empty() else 1)
