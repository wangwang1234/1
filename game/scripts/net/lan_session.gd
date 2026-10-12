extends Node



signal room_changed
signal status_changed(message: String)
signal match_requested(config: Dictionary)
signal simulation_ready
signal snapshot_received(packet: Dictionary)
signal session_ended(reason: String)
signal resume_received
var discovery := LanDiscovery.new()
var reconnecting := false
var _token := ""
var _tokens := {}
var _reserved := {}
var _resume_wait := {}
var _joining := {}
var _endpoint := ""
var _port := 0
var _reconnect_age := 0.0
var _retry_age := 0.0
var _attempt_age := 0.0

var role: = "offline"
var roster: = {}
var room_options: = {"mode": "full"}
var config: = {}
var running: = false
var loading: = false
var status: = "连接同一 Wi-Fi 或路由器，即可联机"
var local_profile: = {"name": "玩家", "team": "blue", "skin": "gold", "weapon": "pistol", "ready": false}
var world: SimWorld
var peer_hams: = {}
var event_buffer := NetEventBuffer.new()
var queued_events: Array:
	get:
		return event_buffer.frames
var snapshots_sent: = 0
var snapshots_received: = 0
var snapshot_bytes: = 0
var _loaded: = {}
var _since: = 0.0
var _send_seq: = 0
var _action_seq: = 0
var _last_input: = {}
var _last_action: = {}
var _input_age: = {}
var _snapshot_frames: = 0
var _pending_events: Array = []
var _kill_events: Array = []
var _last_kill_event := 0
var _signature: = ""
var _net: Dictionary
var chunk_buffer := NetSnapshotChunks.new()
var _chunks: Dictionary:
	get:
		return chunk_buffer.frames
var repaired_snapshots := 0
var _last_snapshot_tick: = -1
var metrics: = NetMetrics.new()
var _consumed_input: = {}
var _consumed_action: = {}
var _probe_age: = 0.0
var _probe_seq: = 0
var _probes: = {}
var _baseline: = {}
const CHUNK_BYTES := NetSnapshotChunks.CHUNK_BYTES


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Host-authoritative star topology (up to network.json maxPlayers). Do not relay peer-list
	# notifications to old transports while a replacement connection is admitted.
	multiplayer.server_relay = false
	_net = Data.load_json("network")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_lost)


func active() -> bool:
	return role != "offline"


func is_host() -> bool:
	return role == "host"


func local_id() -> int:
	return multiplayer.get_unique_id() if active() else 1


func _can_send_to(id: int) -> bool:
	if not multiplayer.multiplayer_peer is ENetMultiplayerPeer or not multiplayer.get_peers().has(id):
		return false
	var peer := (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(id)
	return peer != null and peer.is_active() and peer.get_state() == ENetPacketPeer.STATE_CONNECTED and peer.get_channels() > 0


func signature() -> String:
	if _signature.is_empty():
		var parts: = PackedStringArray([str(_net.protocol), str(ProjectSettings.get_setting("application/config/version", ""))])
		for file in ["rules", "weapons", "evolutions", "abilities", "gadgets", "talents", "pets", "skins", "units", "progression", "map_layout", "network", "difficulty"]:
			parts.append(JSON.stringify(Data.load_json(file), "", true))
		for file in ["res://data/kill_config.tres", "res://data/kill_config_calibrated.tres"]:
			parts.append(FileAccess.get_file_as_string(file))
		_signature = "|".join(parts).sha256_text()
	return _signature


## Seats in the room: maxPlayers, but never more than both teams of the chosen map hold.
func capacity(mode: String = "") -> int:
	var m: = mode if not mode.is_empty() else String(room_options.get("mode", "full"))
	return mini(int(_net.maxPlayers), 2 * team_size(m))


static func team_size(mode: String) -> int:
	return int(Lobby.TEAM_SIZE.get(mode, Lobby.TEAM_SIZE.full))


func team_count(team: String, except: int = 0) -> int:
	var n: = 0
	for id in roster:
		if id != except and String(roster[id].team) == team:
			n += 1
	return n


## True when this player may sit on that team (their own seat does not count against it).
func team_has_room(team: String, id: int = 0) -> bool:
	return team_count(team, id) < team_size(String(room_options.get("mode", "full")))


func addresses() -> PackedStringArray:
	var out: = PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.is_valid_ip_address() and not ip.contains(":") and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			out.append(ip)
	return out


func _status(message: String) -> void :
	status = message
	status_changed.emit(message)


func host(profile: Dictionary, options: Dictionary, port: int = 0) -> Error:
	leave()
	var enet: = ENetMultiplayerPeer.new()
	# Extra slots let a reconnecting player's new transport arrive before the old one is released.
	var error: = enet.create_server(port if port > 0 else int(_net.port), int(_net.maxPlayers) + int(_net.get("spareConnections", 2)), 4)
	if error != OK:
		_status("无法创建房间：端口被占用或网络不可用")
		return error
	multiplayer.multiplayer_peer = enet
	role = "host"
	_port = port if port > 0 else int(_net.port)
	local_profile = clean_profile(profile)
	room_options = {"mode": "slice" if options.get("mode") == "slice" else "full"}
	roster = {1: local_profile.duplicate()}
	discovery.start_host(_room_advertisement())
	_status("房间已创建，等待其他玩家加入（最多 %d 人）" % capacity())
	room_changed.emit()
	return OK


func join(address: String, profile: Dictionary, port: int = 0) -> Error:
	leave()
	if not address.strip_edges().is_valid_ip_address():
		_status("请输入有效的房主局域网 IP 地址")
		return ERR_INVALID_PARAMETER
	var enet: = ENetMultiplayerPeer.new()
	var error: = enet.create_client(address.strip_edges(), port if port > 0 else int(_net.port), 4)
	if error != OK:
		_status("无法连接：请检查地址和端口")
		return error
	multiplayer.multiplayer_peer = enet
	role = "client"
	discovery.stop()
	_endpoint = address.strip_edges()
	_port = port if port > 0 else int(_net.port)
	local_profile = clean_profile(profile)
	_since = 0
	_status("正在连接房主…")
	room_changed.emit()
	return OK


static func clean_profile(p: Dictionary) -> Dictionary:
	var skin: String = p.skin if p.get("skin") is String else "gold"
	var weapon: String = p.weapon if p.get("weapon") is String else "pistol"
	var nick: String = (p.name if p.get("name") is String else "玩家").strip_edges().substr(0, 16).replace("\n", " ").replace("\r", " ")
	return {"name": nick if not nick.is_empty() else "玩家", "team": "red" if p.get("team") == "red" else "blue",
		"skin": skin if Data.skins().has(skin) else "gold", "weapon": weapon if Data.active_weapons().has(weapon) else "pistol", "ready": false}


func _on_connected() -> void :
	_register.rpc_id(1, signature(), local_profile, _token if reconnecting else "")


@rpc("any_peer", "call_remote", "reliable", 0)
func _register(version: String, profile: Dictionary, token: String = "") -> void :
	if not is_host():
		return
	var sender: = multiplayer.get_remote_sender_id()
	if not _can_send_to(sender):
		return
	if roster.has(sender) and not running and not loading and version == signature():
		_seat_token.rpc_id(sender, _tokens[sender])
		_broadcast_room()
		return
	if version == signature() and running and not token.is_empty():
		_accept_resume(sender, token)
		return
	if version != signature() or running or loading or roster.size() >= capacity():
		_reject.rpc_id(sender, "版本不一致，请使用同一份联机版" if version != signature() else "房间已满或对局已经开始")
		return
	_tokens[sender] = Crypto.new().generate_random_bytes(32).hex_encode()
	_seat_token.rpc_id(sender, _tokens[sender])
	var seat: = clean_profile(profile)
	if not team_has_room(seat.team, sender):
		seat.team = "red" if seat.team == "blue" else "blue"
	roster[sender] = seat
	_joining.erase(sender)
	_broadcast_room()


@rpc("authority", "call_remote", "reliable", 0)
func _reject(reason: String) -> void :
	_fail(reason)


func update_profile(profile: Dictionary) -> void :
	if not active() or running or loading:
		return
	local_profile = clean_profile(profile)
	if is_host():
		_set_profile(1, local_profile)
	else:
		_profile.rpc_id(1, local_profile)


func _set_profile(id: int, p: Dictionary) -> void :
	if not roster.has(id):
		return
	var seat: = clean_profile(p)
	# A full team keeps the player where they were; the lobby greys that option out.
	if seat.team != String(roster[id].team) and not team_has_room(seat.team, id):
		seat.team = String(roster[id].team)
	roster[id] = seat

	for row in roster.values():
		row.ready = false
	_broadcast_room()


@rpc("any_peer", "call_remote", "reliable", 0)
func _profile(p: Dictionary) -> void :
	if is_host() and not loading and not running:
		_set_profile(multiplayer.get_remote_sender_id(), p)


func set_ready(value: bool) -> void :
	if not active() or running or loading:
		return
	if is_host():
		roster[1].ready = value
		_broadcast_room()
	else:
		_ready_player.rpc_id(1, value)


@rpc("any_peer", "call_remote", "reliable", 0)
func _ready_player(value: bool) -> void :
	var sender: = multiplayer.get_remote_sender_id()
	if is_host() and not running and not loading and roster.has(sender):
		roster[sender].ready = value
		_broadcast_room()


func _broadcast_room() -> void :
	discovery.advertisement = _room_advertisement()
	for id in roster:
		if id != 1 and _can_send_to(id):
			_room.rpc_id(id, roster, room_options)
	room_changed.emit()


@rpc("authority", "call_remote", "reliable", 0)
func _room(players: Dictionary, options: Dictionary) -> void :
	if role != "client":
		return
	roster = players
	room_options = options
	# The host may finish the old match while this client is reconnecting.
	if reconnecting or running or loading or world != null:
		_back()
		if role != "client":
			return
	_status("已连接：%d/%d 人，全部准备后由房主开始" % [roster.size(), capacity()])
	room_changed.emit()


func can_start() -> bool:
	if not is_host() or loading or running or roster.size() < int(_net.get("minPlayers", 2)) or roster.size() > capacity():
		return false
	if team_count("blue") > team_size(String(room_options.mode)) or team_count("red") > team_size(String(room_options.mode)):
		return false
	return roster.keys().all(func(id: int) -> bool: return id == 1 or _can_send_to(id)) and roster.values().all( func(p: Dictionary) -> bool: return p.ready)


func start_game() -> bool:
	if not can_start():
		return false
	var players: Array = []
	var count: = {"blue": 0, "red": 0}
	var ids: Array = roster.keys()
	ids.sort()
	for id in ids:
		var p: Dictionary = roster[id].duplicate()
		p.peer_id = id
		p.ctl = "player"
		p.input = "kbm"
		players.append(p)
		count[p.team] += 1
	var size: = int(Lobby.TEAM_SIZE[room_options.mode])
	config = {"network": true, "match_id": Time.get_ticks_usec(), "mode": room_options.mode, "seed": int(Time.get_unix_time_from_system()) % 100000 + 1,
		"players": players, "ai": {"blue": size - int(count.blue), "red": size - int(count.red)}}
	multiplayer.multiplayer_peer.refuse_new_connections = false
	for id in _tokens:
		_tokens[id] = Crypto.new().generate_random_bytes(32).hex_encode()
		_seat_token.rpc_id(id, _tokens[id])
	for id in roster:
		if id != 1:
			_begin.rpc_id(id, config)
	_begin(config)
	discovery.advertisement = _room_advertisement()
	return true


@rpc("authority", "call_remote", "reliable", 0)
func _begin(cfg: Dictionary) -> void :
	config = cfg.duplicate(true)
	config.local_peer = local_id()
	loading = true
	running = false
	_since = 0
	_loaded.clear()
	_baseline.clear()
	event_buffer.clear()
	_kill_events.clear()
	_last_kill_event = 0
	_pending_events.clear()
	_last_input.clear()
	_last_action.clear()
	_input_age.clear()
	_send_seq = 0
	_action_seq = 0
	_snapshot_frames = 0
	chunk_buffer.clear()
	_last_snapshot_tick = -1
	metrics = NetMetrics.new()
	_consumed_input.clear()
	_consumed_action.clear()
	_probes.clear()
	_probe_age = 0.0
	snapshots_sent = 0
	snapshots_received = 0
	repaired_snapshots = 0
	snapshot_bytes = 0
	_status("所有玩家正在加载地图…")
	match_requested.emit(config)


func attach(w: SimWorld) -> void :
	world = w
	world.authoritative = is_host()
	_baseline = NetSnapshot.baseline_index(NetSnapshot.capture(w))
	peer_hams.clear()
	# Seats are matched once by spawn order, then by hamster id (an AI takeover changes ctl).
	var i: = 0
	for h in w.hams:
		if h.ctl == "player" and i < config.players.size():
			config.players[i].ham = h.id
			i += 1
	_map_seats()
	if is_host():
		_loaded[1] = true
		_check_loaded()
	else:
		_loaded_player.rpc_id(1, int(config.match_id), String(_baseline.digest))


@rpc("any_peer", "call_remote", "reliable", 0)
func _loaded_player(match_id: int, digest: String = "") -> void :
	var sender: = multiplayer.get_remote_sender_id()
	if is_host() and loading and roster.has(sender) and match_id == int(config.get("match_id", -1)):
		if not _baseline.is_empty() and digest != String(_baseline.digest):
			_reject.rpc_id(sender, "地图初始状态不一致，请使用同版本并重新建房")
			return
		_loaded[sender] = true
		_loaded["digest"] = digest
		_check_loaded()


func _check_loaded() -> void :
	if world != null and _loaded.has("digest") and String(_loaded.digest) != String(_baseline.digest):
		_fail("地图初始状态不一致，请重新创建房间")
		return
	if world != null and _loaded.has(1) and _loaded.size() == roster.size() + 1:
		for id in roster:
			if id != 1:
				_go.rpc_id(id, int(config.match_id))
		_go(int(config.match_id))


@rpc("authority", "call_remote", "reliable", 0)
func _go(match_id: int) -> void :
	if match_id != int(config.get("match_id", -1)) or not loading:
		return
	loading = false
	running = true
	_since = 0
	_status("局域网对局进行中")
	simulation_ready.emit()


func send_input(h: SimHamster) -> Dictionary:
	if not running or is_host():
		return {}
	_send_seq += 1
	var input: = NetInput.pack(h.inp)
	var command: = {"seq": _send_seq, "input": input, "dash": h.inp.dash, "action": 0}
	_controls.rpc_id(1, int(config.match_id), _send_seq, input)
	if h.inp.dash or h.inp.reload or h.inp.gadget or h.inp.skill or h.inp.card >= 0:
		_action_seq += 1
		command.action = _action_seq
		_actions.rpc_id(1, int(config.match_id), _action_seq, NetInput.pack_actions(h.inp, h.choices, _send_seq))
	h.inp.dash = false
	h.inp.dash_direction = Vector2.ZERO
	h.inp.reload = false
	h.inp.gadget = false
	h.inp.skill = false
	h.inp.card = -1
	return command


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _controls(match_id: int, seq: int, input: Dictionary) -> void :
	var sender: = multiplayer.get_remote_sender_id()
	if not is_host() or not running or match_id != int(config.get("match_id", -1)) or not peer_hams.has(sender) or seq <= int(_last_input.get(sender, 0)):
		return
	if not _reserved.has(sender) and not _resume_wait.has(sender) and NetInput.apply(peer_hams[sender].inp, input):
		_last_input[sender] = seq
		_input_age[sender] = 0.0


@rpc("any_peer", "call_remote", "reliable", 0)
func _actions(match_id: int, seq: int, p: Dictionary) -> void :
	var sender: = multiplayer.get_remote_sender_id()
	if not is_host() or not running or match_id != int(config.get("match_id", -1)) or not peer_hams.has(sender) or seq <= int(_last_action.get(sender, 0)):
		return
	if _reserved.has(sender) or _resume_wait.has(sender):
		return
	var h: SimHamster = peer_hams[sender]
	if NetInput.apply_actions(h.inp, p, h.choices):
		_last_action[sender] = seq
		# Recover missing controls without overwriting newer continuous input.
		if int(p.input_seq) > int(_last_input.get(sender, 0)):
			NetInput.apply(h.inp, p.input)
			_last_input[sender] = int(p.input_seq)
			_input_age[sender] = 0.0


func before_step(dt: float) -> void :
	for id in peer_hams:
		if id == 1:
			continue
		_input_age[id] = float(_input_age.get(id, 0)) + dt
		if float(_input_age[id]) > float(_net.inputTimeout):
			NetInput.clear_continuous(peer_hams[id].inp)
		_consumed_input[id] = int(_last_input.get(id, 0))
		_consumed_action[id] = int(_last_action.get(id, 0))


func publish(events: Array) -> void :
	if not is_host() or not running:
		return
	var recipients: Array = []
	for id in peer_hams:
		if id != 1 and not _reserved.has(id) and not _resume_wait.has(id) and _can_send_to(id):
			recipients.append(id)
	if recipients.is_empty():
		_pending_events.clear()
		_snapshot_frames = 0
		return
	# 击败事件同帧走独立可靠 RPC；不能因普通特效预算或快照节流被丢弃。
	var transient: Array = []
	for event: Dictionary in events:
		if String(event.get("t", "")) == "kill_event":
			for id in recipients:
				_player_defeated.rpc_id(id, int(config.match_id), event)
		else:
			transient.append(event)
	_pending_events.append_array(transient.slice(0, maxi(0, int(_net.eventBatchLimit) - _pending_events.size())))
	_snapshot_frames += 1
	if _snapshot_frames < maxi(1, roundi(60.0 / float(_net.snapshotHz))) and not world.over:
		return
	_snapshot_frames = 0
	var started: = Time.get_ticks_usec()
	var packet: = NetSnapshot.capture(world)
	packet.input_ack = _consumed_input.duplicate()
	packet.action_ack = _consumed_action.duplicate()
	var blob: = NetSnapshot.compress(NetSnapshot.delta(packet, _baseline))
	var parity: Array = NetSnapshotChunks.parity(blob, int(_net.snapshotParityGroup)) if _net.snapshotParityEnabled else []
	var bytes := blob.size() + parity.size() * CHUNK_BYTES
	metrics.encode_ms = lerpf(metrics.encode_ms, float(Time.get_ticks_usec() - started) / 1000.0, 0.1)
	metrics.bytes_transferred(bytes)
	snapshot_bytes += bytes
	snapshots_sent += 1
	var total: = ceili(float(blob.size()) / CHUNK_BYTES)
	for id in recipients:
		for index in total:
			_snapshot_chunk.rpc_id(id, int(config.match_id), world.tick, index, total, blob.slice(index * CHUNK_BYTES, mini(blob.size(), (index + 1) * CHUNK_BYTES)))
		for stripe: Dictionary in parity:
			_snapshot_parity.rpc_id(id, int(config.match_id), world.tick, int(stripe.first), total, blob.size(), stripe.data)
	if not _pending_events.is_empty():
		var encoded: Array = NetSnapshot.encode(_pending_events)
		for id in recipients:
			_events.rpc_id(id, int(config.match_id), world.tick, encoded)
		_pending_events.clear()


@rpc("authority", "call_remote", "unreliable", 2)
func _snapshot_chunk(match_id: int, tick: int, index: int, total: int, data: PackedByteArray) -> void :
	if role != "client" or not running or match_id != int(config.get("match_id", -1)):
		return
	if tick <= _last_snapshot_tick:
		return
	metrics.bytes_transferred(data.size())
	_receive_assembled(tick, chunk_buffer.data(tick, index, total, data))


@rpc("authority", "call_remote", "unreliable", 2)
func _snapshot_parity(match_id: int, tick: int, first: int, total: int, size: int, data: PackedByteArray) -> void:
	if role != "client" or not running or match_id != int(config.get("match_id", -1)) or tick <= _last_snapshot_tick:
		return
	metrics.bytes_transferred(data.size())
	_receive_assembled(tick, chunk_buffer.repair(tick, first, total, size, data))


func _receive_assembled(tick: int, assembled: Dictionary) -> void:
	if assembled.is_empty():
		return
	var blob: PackedByteArray = assembled.blob
	var packet: = NetSnapshot.decompress(blob)
	if packet.is_empty():
		return
	packet = NetSnapshot.expand_delta(packet, _baseline)
	if packet.is_empty():
		return
	if not packet.has("state") or int(packet.state.get("tick", -1)) != tick:
		return
	_last_snapshot_tick = tick
	for key in _chunks.keys():
		if int(key) <= tick:
			_chunks.erase(key)
	snapshots_received += 1
	if int(assembled.repaired) > 0:
		repaired_snapshots += 1
	snapshot_bytes += blob.size()
	metrics.snapshot(tick)
	_since = 0
	snapshot_received.emit(packet)


@rpc("authority", "call_remote", "reliable", 3)
func _events(match_id: int, tick: int, events: Array) -> void :
	if role == "client" and running and match_id == int(config.get("match_id", -1)):
		event_buffer.push(tick, events)


func drain_events() -> Array:
	var out := _kill_events.duplicate()
	_kill_events.clear()
	out.append_array(event_buffer.take(world))
	return out


@rpc("authority", "call_remote", "reliable", 3)
func _player_defeated(match_id: int, event: Dictionary) -> void:
	if role != "client" or not running or match_id != int(config.get("match_id", -1)):
		return
	var sequence := int(event.get("event_id", 0))
	if String(event.get("t", "")) != "kill_event" or sequence <= _last_kill_event:
		return
	_last_kill_event = sequence
	_kill_events.append(event.duplicate(true))


func return_to_room() -> void :
	if not is_host():
		return
	for id in roster:
		if id != 1 and _can_send_to(id):
			_back.rpc_id(id)
	_back()


@rpc("authority", "call_remote", "reliable", 0)
func _back() -> void :
	for id in _reserved.keys():
		roster.erase(id)
		_tokens.erase(id)
	_reserved.clear()
	_resume_wait.clear()
	reconnecting = false
	running = false
	loading = false
	world = null
	peer_hams.clear()
	config.clear()
	_loaded.clear()
	_baseline.clear()
	event_buffer.clear()
	_kill_events.clear()
	_last_kill_event = 0
	_pending_events.clear()
	chunk_buffer.clear()
	_probes.clear()
	for state in [_last_input, _last_action, _consumed_input, _consumed_action, _input_age]:
		state.clear()
	_since = 0.0
	_reconnect_age = 0.0
	_retry_age = 0.0
	_attempt_age = 0.0
	if is_host():
		multiplayer.multiplayer_peer.refuse_new_connections = false
		for p in roster.values():
			p.ready = false
	session_ended.emit("")
	if is_host():
		_broadcast_room()


func _on_peer_connected(id: int) -> void:
	if is_host():
		_joining[id] = float(_net.connectTimeout)


func _on_disconnected(id: int) -> void:
	_joining.erase(id)
	if not is_host() or not roster.has(id):
		return
	if running and peer_hams.has(id) and _tokens.has(id):
		if (peer_hams[id] as SimHamster).ctl != "ai":
			world.kill_system.mark_disconnected(peer_hams[id])
		NetInput.clear(peer_hams[id].inp)
		_reserved[id] = float(_net.reconnectGrace)
		_resume_wait.erase(id)
		_status("%s 暂时断线，保留位置 %d 秒等待重连" % [String(roster[id].name), ceili(float(_net.reconnectGrace))])
		discovery.advertisement = _room_advertisement()
	elif loading:
		var who: = String(roster[id].name)
		roster.erase(id)
		_tokens.erase(id)
		return_to_room()
		_status("%s 在加载时断开，已返回房间" % who)
	else:
		roster.erase(id)
		_tokens.erase(id)
		_status("玩家已离开，等待重新加入")
		for p in roster.values():
			p.ready = false
		_broadcast_room()


func _process(dt: float) -> void :
	discovery.advance(dt)
	for id in _joining.keys():
		_joining[id] -= dt
		if _joining[id] <= 0:
			_joining.erase(id)
			if _can_send_to(id):
				multiplayer.multiplayer_peer.disconnect_peer(id)
	if reconnecting:
		_reconnect_tick(dt)
		return
	for id in _reserved.keys():
		_reserved[id] -= dt
		if _reserved[id] <= 0:
			_hand_to_ai(id)
	for id in _resume_wait.keys():
		_resume_wait[id] -= dt
		if _resume_wait[id] <= 0:
			_resume_wait.erase(id)
			if _can_send_to(id):
				multiplayer.multiplayer_peer.disconnect_peer(id)
	if not active():
		return
	_since += dt
	metrics.advance(dt)
	if running:
		_probe_age += dt
		for token in _probes.keys():
			if float(Time.get_ticks_usec() - int(_probes[token].start)) / 1000000.0 > float(_net.probeTimeout):
				_probes.erase(token)
		if _probe_age >= float(_net.probeInterval):
			_probe_age = 0.0
			for id in roster:
				if id != local_id() and not _reserved.has(id) and not _resume_wait.has(id) and _can_send_to(id):
					_probe_seq += 1
					_probes[_probe_seq] = {"peer": id, "start": Time.get_ticks_usec()}
					_probe.rpc_id(id, int(config.match_id), _probe_seq)
	if loading and _since > float(_net.loadTimeout):
		_fail("加载超时，请重新创建房间")
	elif role == "client" and not running and not loading and roster.is_empty() and _since > float(_net.connectTimeout):
		_fail("连接超时：请确认和房主在同一局域网，并允许游戏访问网络")
	elif role == "client" and running and _since > float(_net.snapshotTimeout):
		_server_lost()


@rpc("any_peer", "call_remote", "unreliable", 1)
func _probe(match_id: int, token: int) -> void :
	var sender: = multiplayer.get_remote_sender_id()
	if running and match_id == int(config.get("match_id", -1)) and roster.has(sender):
		_pong.rpc_id(sender, match_id, token)


@rpc("any_peer", "call_remote", "unreliable", 1)
func _pong(match_id: int, token: int) -> void :
	if not running or match_id != int(config.get("match_id", -1)) or not _probes.has(token):
		return
	var probe: Dictionary = _probes[token]
	if int(probe.peer) != multiplayer.get_remote_sender_id():
		return
	metrics.latency(float(Time.get_ticks_usec() - int(probe.start)) / 1000000.0)
	_probes.erase(token)


func _fail(reason: String) -> void :
	leave()
	_status(reason)
	session_ended.emit(reason)


func leave() -> void :
	discovery.stop()
	reconnecting = false
	_token = ""
	_tokens.clear()
	_reserved.clear()
	_resume_wait.clear()
	_joining.clear()
	role = "offline"
	running = false
	loading = false
	world = null
	peer_hams.clear()
	roster.clear()
	event_buffer.clear()
	_kill_events.clear()
	_last_kill_event = 0
	_pending_events.clear()
	chunk_buffer.clear()
	_probes.clear()
	_baseline.clear()
	config.clear()
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	room_changed.emit()


func _room_advertisement() -> Dictionary:
	return {"name": local_profile.name, "port": _port, "mode": room_options.mode, "signature": signature(),
		"count": roster.size(), "capacity": capacity(), "state": "playing" if running or loading else ("full" if roster.size() >= capacity() else "open")}

func scan_rooms() -> void:
	if not active() and not discovery.scanning:
		discovery.start_scan()

@rpc("authority", "call_remote", "reliable", 0)
func _seat_token(value: String) -> void:
	if role == "client" and value.length() == 64:
		_token = value

func _connection_failed() -> void:
	if reconnecting:
		_close_transport()
		_retry_age = 0.0
	else:
		_fail("连接失败：请检查房主 IP、端口和防火墙")

func _close_transport() -> void:
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _server_lost() -> void:
	if role != "client":
		return
	if reconnecting:
		_close_transport()
		_retry_age = float(_net.reconnectRetry)
		return
	if not running or _token.is_empty() or world == null:
		_fail("房主已离开，连接结束")
		return
	reconnecting = true
	running = false
	_reconnect_age = 0.0
	_retry_age = float(_net.reconnectRetry)
	chunk_buffer.clear()
	event_buffer.clear()
	_probes.clear()
	_kill_events.clear()
	NetInput.clear(peer_hams.get(config.local_peer, world.hams[0]).inp)
	_close_transport()
	_status("连接中断，正在自动重连…")

func _reconnect_tick(dt: float) -> void:
	_reconnect_age += dt
	_retry_age += dt
	_attempt_age += dt
	if _reconnect_age >= float(_net.reconnectGrace) and _reconnect_age - dt < float(_net.reconnectGrace):
		_status("仓鼠暂由 AI 接管，继续尝试重连；可主动返回菜单")
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		if _attempt_age > float(_net.connectTimeout):
			_close_transport()
		return
	if _retry_age < float(_net.reconnectRetry):
		return
	_retry_age = 0.0
	_attempt_age = 0.0
	var enet := ENetMultiplayerPeer.new()
	if enet.create_client(_endpoint, _port, 4) == OK:
		multiplayer.multiplayer_peer = enet

func _map_seats() -> void:
	peer_hams.clear()
	for p in config.get("players", []):
		var h: SimHamster = world.ham_by_id(int(p.get("ham", -1))) if world != null else null
		if h != null and int(p.peer_id) > 0:
			peer_hams[int(p.peer_id)] = h


## A player who missed the reconnect window: their hamster keeps playing under AI control.
func _hand_to_ai(id: int) -> void:
	var who := String(roster.get(id, {}).get("name", "玩家"))
	_reserved.erase(id)
	# 对局结束前保留座位与重连 token；AI 接管后玩家仍可收回控制权。
	if peer_hams.has(id) and world != null:
		world.hand_to_ai(peer_hams[id])
	for key in [_last_input, _last_action, _consumed_input, _consumed_action, _input_age]:
		key.erase(id)
	_status("%s 暂由 AI 接管，仍可重连继续" % who)
	discovery.advertisement = _room_advertisement()


func _accept_resume(sender: int, token: String) -> void:
	var previous := -1
	for id in _tokens:
		if _tokens[id] == token and peer_hams.has(id):
			previous = id
			break
	if previous < 0 or world == null:
		_reject.rpc_id(sender, "重连身份已失效，请重新加入房间")
		return
	_joining.erase(sender)
	var h: SimHamster = peer_hams[previous]
	var profile: Dictionary = roster[previous]
	roster.erase(previous)
	roster[sender] = profile
	peer_hams.erase(previous)
	peer_hams[sender] = h
	_tokens.erase(previous)
	_tokens[sender] = token
	if previous != sender and _can_send_to(previous):
		multiplayer.multiplayer_peer.disconnect_peer(previous)
	_reserved.erase(previous)
	_resume_wait[sender] = float(_net.connectTimeout)
	for key in [_last_input, _last_action, _consumed_input, _consumed_action, _input_age]:
		key.erase(previous)
		key.erase(sender)
	NetInput.clear(h.inp)
	for p in config.players:
		if int(p.peer_id) == previous:
			p.peer_id = sender
	var packet := NetSnapshot.capture(world)
	_resume_state.rpc_id(sender, int(config.match_id), String(_baseline.digest), roster, config.players, NetSnapshot.compress(packet))

@rpc("authority", "call_remote", "reliable", 0)
func _resume_state(match_id: int, digest: String, players: Dictionary, owners: Array, blob: PackedByteArray) -> void:
	if not reconnecting or match_id != int(config.get("match_id", -1)) or digest != String(_baseline.get("digest", "")):
		return
	var packet := NetSnapshot.decompress(blob)
	if packet.is_empty() or not NetSnapshot.apply(world, packet):
		_fail("重连状态恢复失败，请重新创建房间")
		return
	roster = players
	config.players = owners
	config.local_peer = local_id()
	_map_seats()
	chunk_buffer.clear()
	event_buffer.clear()
	_last_snapshot_tick = world.tick
	metrics = NetMetrics.new()
	_since = 0
	reconnecting = false
	running = true
	resume_received.emit()
	if role != "client" or not running or world == null:
		return
	snapshot_received.emit(packet)
	if role != "client" or not running:
		return
	_resume_ack.rpc_id(1, match_id)
	_status("已重连，继续原来的对局")

@rpc("any_peer", "call_remote", "reliable", 0)
func _resume_ack(match_id: int) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if is_host() and running and match_id == int(config.get("match_id", -1)) and _resume_wait.has(sender):
		_resume_wait.erase(sender)
		if peer_hams.has(sender):
			world.resume_player(peer_hams[sender])
		_status("玩家已重连，对局继续")
		discovery.advertisement = _room_advertisement()
