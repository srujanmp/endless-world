extends Node

# Online rooms through a tiny WebSocket relay (relay/ — a Cloudflare Worker).
# The relay only forwards JSON between up to 10 players in a room; all game
# logic runs on the host's machine (world seed, riddle generation, round flow).
#
# On top of that, every pair of players tries a direct WebRTC data channel (full
# mesh, signalled through the relay). While a pair has no open channel (still
# connecting, NAT blocked it, no WebRTC on this build) their traffic goes through the
# relay, so a failed P2P attempt never breaks a game; it only costs latency.
#
# Messages: every packet is a Dictionary with "t" (type). The relay adds "from".
#   relay -> us : welcome{id, peers}, join{id,name}, leave{id}, error{msg}, host_left
#   game        : start{seed, qtype, topic, round}, riddle{data}, hint{idx}, topic{topic},
#                 pos{x,y,a,f,s,c}, won{name, answer}, chat{text}, hello{c}

signal connected(my_id: int)
signal peer_joined(id: int, player_name: String)
signal peer_left(id: int)
signal message(from: int, data: Dictionary)
signal disconnected(reason: String)

const MAX_PLAYERS := 10
const HOST_ONLY := ["start", "riddle", "topic"]
const DEFAULT_RELAY := "wss://endless-worlds-relay.srujanmpadmashali.workers.dev"
const COLORS: Array[Color] = [
	Color("4cc9f0"), Color("f72585"), Color("ffd60a"), Color("80ed99"), Color("ff8c42"),
	Color("b388ff"), Color("ff595e"), Color("00f5d4"), Color("f4a261"), Color("e0e0e0"),
]

var relay_url := DEFAULT_RELAY
var ws: WebSocketPeer
var my_id := 0
var room_code := ""
var player_name := "Player"
var peers := {}            # id -> name (includes me)
var peer_chars := {}       # id -> character index (from "hello" messages)
var active := false        # inside a connected room
var round_data := {}       # last "start" from host
var round_riddle := {}     # last riddle for this round (cached for late scene loads)
var round_hints: Array = []  # hint idxs already taken this round
var room_topic := ""       # topic the host picked for the next round (shown in the lobby)
var _connecting_for := 0.0

# Several public STUN servers: if one is down or blocked, ICE still finds our public address.
const ICE_SERVERS := [{"urls": ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302",
	"stun:stun.cloudflare.com:3478"]}]
const P2P_TIMEOUT := 12.0       # seconds to get a channel open before using the relay for that peer
const P2P_MAX_BYTES := 60000    # bigger packets (voice clips) use the relay: Safari caps data-channel messages at 64 KB
const RELAY_ONLY := ["welcome", "join", "leave", "error", "host_left", "rtc"]  # never accepted from a peer directly
const P2P_TRIES := 3            # attempts per peer (a NAT that blocks P2P fails every time; retries fix blips)
var rtc := {}                   # peer id -> {pc, ch, t (seconds connecting), open, go}
var rtc_tries := {}             # peer id -> attempts made (only by the side that offers)
var rtc_retry := {}             # peer id -> seconds until the next attempt
var p2p_available := true       # false once WebRTC fails to start (desktop build without the extension)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep the connection alive behind paused menus
	var env := EnvLoader.load_env()
	relay_url = str(env.get("RELAY_URL", ProjectSettings.get_setting("application/config/relay_url", DEFAULT_RELAY))).trim_suffix("/")
	set_process(false)


func is_host() -> bool:
	return active and my_id == 1


func color_of(id: int) -> Color:
	return COLORS[(maxi(id, 1) - 1) % COLORS.size()]


func host_room(name: String, code: String = "") -> void:
	var chars := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # no 0/O/1/I confusion
	while code.length() < 5:
		code += chars[randi() % chars.length()]
	_open(code, name, true)


func join_room(code: String, name: String) -> void:
	_open(code.strip_edges().to_upper(), name, false)


func _open(code: String, name: String, host: bool) -> void:
	leave()
	room_code = code
	player_name = name.strip_edges().left(16) if not name.strip_edges().is_empty() else "Player"
	ws = WebSocketPeer.new()
	ws.inbound_buffer_size = 1 << 20
	ws.outbound_buffer_size = 1 << 20  # voice clips for the host's AI server
	var url := "%s/room/%s?name=%s&host=%d" % [relay_url, code, player_name.uri_encode(), 1 if host else 0]
	print("[Net] connecting ", url)
	var err := ws.connect_to_url(url)
	if err != OK:
		disconnected.emit("Could not open connection (%s)" % error_string(err))
		return
	_connecting_for = 0.0
	set_process(true)


func send(data: Dictionary, to: int = 0) -> void:
	if ws == null or ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var buf := JSON.stringify(data).to_utf8_buffer()
	var small := buf.size() <= P2P_MAX_BYTES
	if to != 0:
		if small and is_direct(to):
			rtc[to].ch.put_packet(buf)
		else:
			_relay(data, to)
		return
	var via_relay := []
	for id in peers:
		if id == my_id:
			continue
		if small and is_direct(id):
			rtc[id].ch.put_packet(buf)
		else:
			via_relay.append(id)
	if via_relay.size() == peers.size() - 1:
		_relay(data)   # nobody is direct: one broadcast instead of one message per peer
	else:
		for id in via_relay:
			_relay(data, id)


func _relay(data: Dictionary, to: int = 0) -> void:
	if ws == null or ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var d := data.duplicate()
	if to != 0:
		d["to"] = to
	ws.send_text(JSON.stringify(d))


# Is this peer on a working direct WebRTC link? A link that ICE reports as disconnected
# stops carrying traffic at once (to the relay) instead of when it finally fails.
func is_direct(id: int) -> bool:
	return rtc.has(id) and rtc[id].open and rtc[id].pc.get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED


func leave() -> void:
	for id in rtc.keys():
		_rtc_close(id)
	rtc_tries.clear()
	rtc_retry.clear()
	if ws:
		ws.close()
	ws = null
	active = false
	my_id = 0
	peers.clear()
	peer_chars.clear()
	round_data = {}
	round_riddle = {}
	round_hints = []
	room_topic = ""
	set_process(false)


func _process(delta: float) -> void:
	if ws == null:
		return
	ws.poll()
	var state := ws.get_ready_state()
	if state == WebSocketPeer.STATE_CONNECTING:
		_connecting_for += delta
		if _connecting_for > 8.0:
			_fail("Can't reach the multiplayer relay at %s" % relay_url)
		return
	if state == WebSocketPeer.STATE_CLOSED:
		print("[Net] socket closed: code %d reason '%s' after %.1f s" % [ws.get_close_code(), ws.get_close_reason(), Time.get_ticks_msec() / 1000.0])
		_fail("Connection closed (%d)" % ws.get_close_code() if not active else "Disconnected from room")
		return
	while ws and ws.get_available_packet_count() > 0:
		var data = JSON.parse_string(ws.get_packet().get_string_from_utf8())
		if typeof(data) == TYPE_DICTIONARY:
			_handle(data)
	_poll_rtc(delta)


func _fail(reason: String) -> void:
	print("[Net] ", reason)
	var was_room := room_code
	leave()
	if not was_room.is_empty():
		disconnected.emit(reason)


func _handle(d: Dictionary) -> void:
	match str(d.get("t", "")):
		"welcome":
			my_id = int(d.id)
			active = true
			peers.clear()
			for p in d.get("peers", []):
				peers[int(p.id)] = str(p.name)
			peers[my_id] = player_name
			peer_chars[my_id] = Global.character
			print("[Net] joined room %s as #%d" % [room_code, my_id])
			for id in peers:
				_rtc_start(id)
			send({"t": "hello", "c": Global.character})
			connected.emit(my_id)
		"join":
			var id := int(d.id)
			peers[id] = str(d.name)
			_rtc_close(id)   # a reused id: drop any stale link
			rtc_tries.erase(id)
			_rtc_start(id)
			send({"t": "hello", "c": Global.character}, id)   # tell the newcomer what I look like
			if is_host() and not room_topic.is_empty():
				send({"t": "topic", "topic": room_topic}, id)
			if is_host() and not round_data.is_empty():
				# Late joiner: hand them the running round so they drop straight in.
				send(round_data.duplicate(), id)
				if not round_riddle.is_empty():
					send({"t": "riddle", "data": round_riddle}, id)
				for idx in round_hints:
					send({"t": "hint", "idx": idx}, id)
			peer_joined.emit(id, str(d.name))
		"leave":
			_rtc_close(int(d.id))
			rtc_tries.erase(int(d.id))
			rtc_retry.erase(int(d.id))
			peers.erase(int(d.id))
			peer_left.emit(int(d.id))
		"error":
			_fail(str(d.get("msg", "Relay error")))
		"host_left":
			_fail("The host left the room")
		"rtc":
			_on_rtc(int(d.get("from", 0)), d)
		_:
			var t := str(d.get("t", ""))
			if t == "hello":
				peer_chars[int(d.get("from", 0))] = int(d.get("c", 0))
			if t in HOST_ONLY and int(d.get("from", 0)) != 1:
				return  # the relay stamps the real sender; ignore forged round control
			# Cache round state so a scene that loads late still catches up.
			match t:
				"start":
					round_data = d
					round_riddle = {}
					round_hints = []
				"riddle":
					round_riddle = d.get("data", {})
				"hint":
					round_hints.append(int(d.idx))
				"topic":
					room_topic = str(d.get("topic", "")).left(40)
			message.emit(int(d.get("from", 0)), d)


# Scene for the running round: the riddle island or co-op Survival.
func round_scene() -> String:
	return "res://survival/survival.tscn" if str(round_data.get("mode", "island")) == "survival" else "res://map_components/map.tscn"


func in_survival() -> bool:
	return active and str(round_data.get("mode", "")) == "survival"


# Invite link for the current room: the game's own URL with ?room=CODE.
func invite_link() -> String:
	var base := "https://endlessworlds.github.io/endless-worlds/"
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("location.origin + location.pathname", true)
		if typeof(v) == TYPE_STRING and not str(v).is_empty():
			base = str(v)
	return "%s?room=%s" % [base, room_code]


# Room code from an invite link this page was opened with (web), once.
var _invite_checked := false

func take_invite_code() -> String:
	if _invite_checked or not OS.has_feature("web"):
		return ""
	_invite_checked = true
	var v = JavaScriptBridge.eval("""(function () {
		var c = new URLSearchParams(location.search).get('room') || '';
		if (c) { try { history.replaceState(null, '', location.pathname); } catch (e) {} }
		return c;
	})()""", true)
	var code := str(v).strip_edges().to_upper() if typeof(v) == TYPE_STRING else ""
	return code if code.length() >= 4 and code.length() <= 8 else ""


# Host helper: change the room's topic (lobby + next rounds) and tell everyone.
func set_topic(topic: String) -> void:
	room_topic = topic.strip_edges().left(40)
	if is_host():
		send({"t": "topic", "topic": room_topic})


# Host helper: start a round for everyone (and remember it locally).
func host_start_round(topic: String, round_no: int, mode := "") -> void:
	var pool := [Global.QuestionType.MCQ, Global.QuestionType.FILL_BLANK, Global.QuestionType.WORDLE,
		Global.QuestionType.WHACK, Global.QuestionType.WORD_LOCK, Global.QuestionType.KBC]
	room_topic = topic
	if mode.is_empty():
		mode = str(round_data.get("mode", "island"))
	round_data = {"t": "start", "seed": randi(), "qtype": pool.pick_random(), "topic": topic, "round": round_no, "mode": mode}
	round_riddle = {}
	round_hints = []
	send(round_data.duplicate())


# --- WebRTC peer-to-peer ------------------------------------------------------------------
# The higher id of each pair offers (so offers never cross); the other side answers.
# When a side's channel opens it sends "go" through the relay and switches to direct. The
# receiver reads direct packets only after that "go": everything the sender put on the
# relay before it has arrived by then, so switching paths never reorders messages.

func _rtc_start(id: int) -> void:
	if id >= my_id or not p2p_available:
		return
	rtc_tries[id] = int(rtc_tries.get(id, 0)) + 1
	_rtc_open(id, true)


func _rtc_open(id: int, offer: bool) -> void:
	_rtc_close(id)
	if not p2p_available or not peers.has(id):
		return
	var pc := WebRTCPeerConnection.new()
	if pc.initialize({"iceServers": ICE_SERVERS}) != OK:
		p2p_available = false
		print("[Net] WebRTC unavailable on this build; using the relay only")
		return
	# Negotiated channel (same id on both sides): no data_channel_received dance, and it exists before the offer.
	var ch := pc.create_data_channel("game", {"negotiated": true, "id": 1})
	if ch == null:
		pc.close()
		return
	pc.session_description_created.connect(_on_local_sdp.bind(id))
	pc.ice_candidate_created.connect(_on_local_ice.bind(id))
	rtc[id] = {"pc": pc, "ch": ch, "t": 0.0, "open": false, "go": false}
	if offer:
		pc.create_offer()


func _rtc_close(id: int) -> void:
	var r = rtc.get(id)
	if r == null:
		return
	rtc.erase(id)
	r.ch.close()
	r.pc.close()


func _on_local_sdp(type: String, sdp: String, id: int) -> void:
	if rtc.has(id):
		# Relay the SDP before applying it: applying it starts ICE, and candidates must not overtake it.
		_relay({"t": "rtc", "k": type, "sdp": sdp}, id)
		rtc[id].pc.set_local_description(type, sdp)


func _on_local_ice(media: String, index: int, cand: String, id: int) -> void:
	_relay({"t": "rtc", "k": "ice", "m": media, "i": index, "n": cand}, id)


# Signalling from a peer, through the relay (which stamped the real sender).
func _on_rtc(from: int, d: Dictionary) -> void:
	var k := str(d.get("k", ""))
	if k == "offer":
		if from < my_id:
			return   # not the offering side of this pair
		_rtc_open(from, false)
	var r = rtc.get(from)
	if r == null:
		return
	match k:
		"ice":
			r.pc.add_ice_candidate(str(d.get("m", "")), int(d.get("i", 0)), str(d.get("n", "")))
		"offer", "answer":
			r.pc.set_remote_description(k, str(d.get("sdp", "")))   # an offer makes Godot create our answer
		"go":
			r.go = true


func _poll_rtc(delta: float) -> void:
	for id in rtc_retry.keys():
		rtc_retry[id] -= delta
		if rtc_retry[id] <= 0.0:
			rtc_retry.erase(id)
			if peers.has(id) and not rtc.has(id):
				_rtc_start(id)
	for id in rtc.keys():
		if not rtc.has(id):   # closed while handling an earlier packet
			continue
		var r: Dictionary = rtc[id]
		r.pc.poll()
		var ch: WebRTCDataChannel = r.ch
		if ch.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			if not r.open:
				_relay({"t": "rtc", "k": "go"}, id)   # before any direct packet (see above)
				r.open = true
				print("[Net] direct P2P link to #%d" % id)
			while r.go and rtc.has(id) and ch.get_available_packet_count() > 0:
				var data = JSON.parse_string(ch.get_packet().get_string_from_utf8())
				if typeof(data) == TYPE_DICTIONARY and not (str(data.get("t", "")) in RELAY_ONLY):
					data["from"] = id   # the channel itself proves the sender
					_handle(data)
			continue
		r.t += delta
		var state: int = r.pc.get_connection_state()
		if r.open or r.t > P2P_TIMEOUT or state == WebRTCPeerConnection.STATE_FAILED or state == WebRTCPeerConnection.STATE_CLOSED:
			_rtc_close(id)
			# The offering side retries a few times (a blip, or a dropped link mid-game).
			if id < my_id and int(rtc_tries.get(id, 0)) < P2P_TRIES:
				rtc_retry[id] = 3.0
				print("[Net] no direct link to #%d yet; relay meanwhile, retrying" % id)
			else:
				print("[Net] no direct link to #%d; using the relay" % id)
